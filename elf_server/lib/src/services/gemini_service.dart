import 'dart:convert';
import 'dart:async';
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

  // ── PUBLIC ────────────────────────────────────────────────────────────────

  /// Sends [userMessage] along with optional [history] (oldest → newest).
  /// The history should NOT include the current [userMessage] — it is appended
  /// automatically as the final turn.
  Future<String> generateContent(
    String userMessage, {
    List<ChatTurn> history = const [],
  }) async {
    // Build the contents array: history turns + the new user message
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
    return _extractText(await _withRetry(body));
  }

  Future<String> generateTitle(String userPrompt, String aiResponse) async {
    final prompt =
        'Create a chat title of 3 to 6 words for this conversation.\n'
        'Reply with ONLY the title — no quotes, no punctuation, no explanation.\n\n'
        'User: $userPrompt\n\n'
        'Assistant: $aiResponse';

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
        'maxOutputTokens': 30,
        'thinkingConfig': {'thinkingBudget': 0},
      },
    };
    return _sanitise(_extractText(await _withRetry(body)));
  }

  // ── RETRY ─────────────────────────────────────────────────────────────────

  static const List<int> _retryDelays = [5, 20, 40];

  Future<Map<String, dynamic>> _withRetry(Map<String, dynamic> body) async {
    for (int i = 0; i <= _retryDelays.length; i++) {
      try {
        return await _rawPost(body);
      } on _RateLimitEx {
        final isLastAttempt = i == _retryDelays.length;
        if (isLastAttempt) {
          throw Exception(
            'Gemini rate limit: all ${_retryDelays.length + 1} attempts failed. '
            'Please try again in a minute.',
          );
        }
        final wait = _retryDelays[i];
        await Future<void>.delayed(Duration(seconds: wait));
      }
    }
    throw Exception('_withRetry: unreachable');
  }

  // ── HTTP ──────────────────────────────────────────────────────────────────

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
    if (res.statusCode == 403) {
      throw Exception('API key invalid or no permissions');
    }
    if (res.statusCode == 400) throw Exception('Bad request: ${res.body}');
    throw Exception('Gemini HTTP ${res.statusCode}: ${res.body}');
  }

  // ── PARSING ───────────────────────────────────────────────────────────────

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

/// Private sentinel — only caught inside [GeminiService._withRetry].
class _RateLimitEx implements Exception {
  const _RateLimitEx();
  @override
  String toString() => 'Gemini rate limit hit (429)';
}