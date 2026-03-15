import 'package:elf_server/src/services/gemini_service.dart';
import 'package:serverpod/serverpod.dart';

class ChatEndpoint extends Endpoint {
  // How many previous turns (user + assistant pairs) to include in context.
  // 10 turns = 20 messages. Raise or lower based on your token budget.
  static const int _maxHistoryTurns = 10;

  // ─────────────────────────────────────────────────────────────────────────
  // sendMessage
  // ─────────────────────────────────────────────────────────────────────────

  /// [history] is an optional flat list of serialised turns, alternating
  /// user / assistant, oldest first:
  ///   ["user: hello", "assistant: hi!", "user: how are you?", ...]
  ///
  /// The client must NOT include the current [message] in [history] —
  /// the endpoint appends it automatically.
  Future<String> sendMessage(
    Session session,
    String message, {
    List<String>? history,
  }) async {
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    final preview = message.length > 50
        ? '${message.substring(0, 50)}...'
        : message;
    session.log('Chat message received: $preview');
    session.log('History turns supplied: ${history?.length ?? 0}');

    // Parse the flat string list into typed ChatTurn objects.
    final parsedHistory = _parseTurns(history);

    final geminiService = _buildService(session);
    final response = await geminiService.generateContent(
      message,
      history: parsedHistory,
    );

    session.log('AI response generated successfully');
    return response;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // generateTitle
  // ─────────────────────────────────────────────────────────────────────────
  Future<String> generateTitle(
    Session session,
    String userPrompt,
    String aiResponse,
  ) async {
    session.log('Generating conversation title…');

    try {
      if (userPrompt.trim().isEmpty || aiResponse.trim().isEmpty) {
        session.log(
          'generateTitle: empty inputs, returning fallback',
          level: LogLevel.warning,
        );
        return 'New Chat';
      }

      final geminiService = _buildService(session);
      final title = await geminiService.generateTitle(userPrompt, aiResponse);

      if (title.isEmpty || title.split(' ').length > 10) {
        session.log(
          'generateTitle: suspicious title "$title", returning fallback',
          level: LogLevel.warning,
        );
        return 'New Chat';
      }

      session.log('Title generated: "$title"');
      return title;
    } catch (e, stackTrace) {
      session.log(
        'Title generation failed: $e\n$stackTrace',
        level: LogLevel.error,
      );
      return 'New Chat';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  GeminiService _buildService(Session session) {
    final apiKey = session.passwords['geminiApiKey'];
    if (apiKey == null || apiKey.isEmpty) {
      session.log(
        'geminiApiKey not found in passwords.yaml',
        level: LogLevel.error,
      );
      throw Exception('Gemini API key not configured');
    }
    return GeminiService(apiKey: apiKey);
  }

  /// Converts the flat `["user: …", "assistant: …", …]` list that the Flutter
  /// client sends into [ChatTurn] objects, capped at [_maxHistoryTurns] pairs.
  ///
  /// Each string must start with `"user: "` or `"assistant: "` (case-insensitive).
  /// Malformed entries are silently skipped to avoid crashing the request.
  List<ChatTurn> _parseTurns(List<String>? raw) {
    if (raw == null || raw.isEmpty) return const [];

    final turns = <ChatTurn>[];

    for (final entry in raw) {
      if (entry.toLowerCase().startsWith('user: ')) {
        turns.add(ChatTurn(role: 'user', text: entry.substring(6).trim()));
      } else if (entry.toLowerCase().startsWith('assistant: ')) {
        // Gemini expects the assistant role to be called "model"
        turns.add(ChatTurn(role: 'model', text: entry.substring(11).trim()));
      }
      // unknown prefix → skip
    }

    // Keep only the most recent N turns to stay within the token budget.
    // Each "turn pair" = 1 user + 1 assistant message = 2 entries.
    final maxEntries = _maxHistoryTurns * 2;
    if (turns.length > maxEntries) {
      return turns.sublist(turns.length - maxEntries);
    }
    return turns;
  }
}