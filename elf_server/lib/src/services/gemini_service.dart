import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// A single turn in the conversation history passed from the client.
class ChatTurn {
  final String role; // 'user' or 'model'
  final String text;

  const ChatTurn({required this.role, required this.text});

  Map<String, dynamic> toGeminiContent() => {
        'role': role,
        'parts': [
          {'text': text}
        ],
      };
}

class GeminiService {
  final String apiKey;
  GeminiService({required this.apiKey});

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.5-flash';

  // ── PUBLIC: STREAMING ────────────────────────────────────────────────────

  /// Streams text tokens from Gemini as they arrive via SSE.
  ///
  /// The caller receives individual text chunks (not full sentences).
  /// The stream closes naturally when Gemini finishes.
  /// Errors are added to the stream and it is then closed.
  Stream<String> streamContent(
    String userMessage, {
    List<ChatTurn> history = const [],
  }) async* {
    final contents = [
      ...history.map((t) => t.toGeminiContent()),
      {
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ],
      },
    ];

    final body = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 2048,
      },
      'safetySettings': _safetySettings,
    };

    // Use the streamGenerateContent endpoint with alt=sse
    final url = Uri.parse(
      '$_baseUrl/models/$_model:streamGenerateContent?key=$apiKey&alt=sse',
    );

    late http.StreamedResponse response;

    try {
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);

      response = await request.send().timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw Exception('Connection timed out. Please check your network.');
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    }

    if (response.statusCode == 429) {
      throw Exception(
        'Too many requests. Please wait a moment and try again.',
      );
    }
    if (response.statusCode == 403) {
      throw Exception('API key invalid or no permissions.');
    }
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Gemini HTTP ${response.statusCode}: $body');
    }

    // SSE stream: each event is a "data: {...json...}" line
    // We accumulate bytes into lines and parse each SSE event.
    final buffer = StringBuffer();

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer.write(chunk);

      // Process all complete lines in the buffer
      String content = buffer.toString();
      buffer.clear();

      final lines = content.split('\n');

      // The last element may be an incomplete line — keep it in the buffer
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            final text = _extractTextFromChunk(json);
            if (text != null && text.isNotEmpty) {
              yield text;
            }
          } catch (_) {
            // Malformed chunk — skip silently
          }
        }
      }

      // Keep the incomplete last line in the buffer
      if (lines.last.isNotEmpty) {
        buffer.write(lines.last);
      }
    }

    // Process any remaining data in the buffer after stream closes
    final remaining = buffer.toString().trim();
    if (remaining.startsWith('data: ')) {
      final jsonStr = remaining.substring(6).trim();
      if (jsonStr.isNotEmpty && jsonStr != '[DONE]') {
        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final text = _extractTextFromChunk(json);
          if (text != null && text.isNotEmpty) {
            yield text;
          }
        } catch (_) {}
      }
    }
  }

  // ── PUBLIC: TITLE GENERATION (non-streaming, short request) ─────────────

  /// Generates a short title from a single prompt/response pair.
  /// Kept for backward compatibility — delegates to [generateTitleFromTurns].
  Future<String> generateTitle(String userPrompt, String aiResponse) {
    return generateTitleFromTurns([
      ChatTurn(role: 'user', text: userPrompt),
      ChatTurn(role: 'model', text: aiResponse),
    ]);
  }

  /// Generates a short title from an arbitrary list of turns.
  ///
  /// Used both for the initial title (first exchange) and for periodic
  /// checkpoint updates (anchor exchange + a window of recent messages).
  /// Turns are rendered in order as "User: ..." / "Assistant: ..." lines.
  Future<String> generateTitleFromTurns(List<ChatTurn> turns) async {
    if (turns.isEmpty) return 'New Chat';

    final transcript = turns.map((t) {
      final label = t.role == 'user' ? 'User' : 'Assistant';
      return '$label: ${t.text}';
    }).join('\n\n');

    final prompt =
        'Create a chat title of 5 to 8 words that reflects the overall '
        'topic of this conversation so far.\n'
        'Reply with ONLY the title — no quotes, no punctuation, no explanation.\n\n'
        '$transcript';

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 40,
        'thinkingConfig': {'thinkingBudget': 0},
      },
    };

    return _sanitise(_extractText(await _withRetry(body)));
  }

  // ── PRIVATE: CHUNK PARSING ───────────────────────────────────────────────

  /// Extracts the text from a single SSE chunk JSON object.
  /// Returns null if there is no usable text in this chunk.
  String? _extractTextFromChunk(Map<String, dynamic> json) {
    // Check for safety block at the prompt level
    final feedback = json['promptFeedback'] as Map<String, dynamic>?;
    final blockReason = feedback?['blockReason'] as String?;
    if (blockReason != null) {
      throw Exception('Prompt blocked by safety filters: $blockReason');
    }

    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return null;

    final candidate = candidates[0] as Map<String, dynamic>;

    // Safety block at response level
    if (candidate['finishReason'] == 'SAFETY') {
      throw Exception('Response blocked by safety filters.');
    }

    final parts = (candidate['content'] as Map<String, dynamic>?)?['parts']
        as List<dynamic>?;
    if (parts == null || parts.isEmpty) return null;

    for (final part in parts) {
      final p = part as Map<String, dynamic>?;
      if (p == null || p['thought'] == true) continue;
      final text = p['text'] as String?;
      if (text != null && text.isNotEmpty) return text;
    }

    return null;
  }

  // ── RETRY (used only by generateTitle) ──────────────────────────────────

  static const List<int> _retryDelays = [5, 20, 40];

  Future<Map<String, dynamic>> _withRetry(Map<String, dynamic> body) async {
    for (int i = 0; i <= _retryDelays.length; i++) {
      try {
        return await _rawPost(body);
      } on _RateLimitEx {
        final isLastAttempt = i == _retryDelays.length;
        if (isLastAttempt) {
          throw Exception(
            'Gemini rate limit: all ${_retryDelays.length + 1} attempts failed.',
          );
        }
        await Future<void>.delayed(Duration(seconds: _retryDelays[i]));
      }
    }
    throw Exception('_withRetry: unreachable');
  }

  Future<Map<String, dynamic>> _rawPost(Map<String, dynamic> body) async {
    final url =
        Uri.parse('$_baseUrl/models/$_model:generateContent?key=$apiKey');

    final http.Response res;
    try {
      res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    }

    if (res.statusCode == 200) {
      try {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Could not decode Gemini response');
      }
    }
    if (res.statusCode == 429) throw _RateLimitEx();
    if (res.statusCode == 403) throw Exception('API key invalid or no permissions');
    if (res.statusCode == 400) throw Exception('Bad request: ${res.body}');
    throw Exception('Gemini HTTP ${res.statusCode}: ${res.body}');
  }

  String _extractText(Map<String, dynamic> res) {
    final feedback = res['promptFeedback'] as Map<String, dynamic>?;
    final blockReason = feedback?['blockReason'] as String?;
    if (blockReason != null) {
      throw Exception('Prompt blocked by safety filters: $blockReason');
    }

    final candidates = res['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No candidates in Gemini response');
    }

    final candidate = candidates[0] as Map<String, dynamic>;
    if (candidate['finishReason'] == 'SAFETY') {
      throw Exception('Response blocked by safety filters');
    }

    final parts =
        (candidate['content'] as Map<String, dynamic>?)?['parts']
            as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw Exception('No parts in Gemini response');
    }

    for (final part in parts) {
      final p = part as Map<String, dynamic>?;
      if (p == null || p['thought'] == true) continue;
      final text = p['text'] as String?;
      if (text != null && text.trim().isNotEmpty) return text.trim();
    }

    throw Exception('No usable text in Gemini parts: ${jsonEncode(parts)}');
  }

  String _sanitise(String raw) => raw
      .replaceAll(RegExp(r'''^["'`*]+|["'`*]+$'''), '')
      .replaceAll(RegExp(r'\n+'), ' ')
      .trim();

  static const List<Map<String, String>> _safetySettings = [
    {
      'category': 'HARM_CATEGORY_HARASSMENT',
      'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
    },
    {
      'category': 'HARM_CATEGORY_HATE_SPEECH',
      'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
    },
  ];
}

class _RateLimitEx implements Exception {
  const _RateLimitEx();
}