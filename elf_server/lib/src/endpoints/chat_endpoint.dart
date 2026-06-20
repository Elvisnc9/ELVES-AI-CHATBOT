import 'dart:async';
import 'package:elf_server/src/services/gemini_service.dart';
import 'package:serverpod/serverpod.dart';

class ChatEndpoint extends Endpoint {
  static const int _maxHistoryTurns = 10;

  // ── STREAMING sendMessage ────────────────────────────────────────────────

  /// Streams AI response tokens as they arrive from Gemini.
  ///
  /// [history] is an optional flat list of serialised turns, alternating
  /// user / assistant, oldest first:
  ///   ["user: hello", "assistant: hi!", ...]
  ///
  /// The client must NOT include the current [message] in [history].
  /// Each yielded String is a raw text chunk (not a full sentence).
  Stream<String> sendMessage(
    Session session,
    String message, {
    List<String>? history,
  }) async* {
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    final preview = message.length > 50
        ? '${message.substring(0, 50)}...'
        : message;
    session.log('Streaming chat message: $preview');
    session.log('History turns supplied: ${history?.length ?? 0}');

    final parsedHistory = _parseTurns(history);
    final geminiService = _buildService(session);

    // Pipe Gemini's stream directly to the Serverpod stream.
    // Any exception thrown inside geminiService.streamContent()
    // will propagate through the stream as an error event.
    await for (final chunk in geminiService.streamContent(
      message,
      history: parsedHistory,
    )) {
      yield chunk;
    }

    session.log('Streaming complete');
  }

  // ── generateTitle (single prompt/response pair — kept for compatibility) ─

  Future<String> generateTitle(
    Session session,
    String userPrompt,
    String aiResponse,
  ) async {
    session.log('Generating conversation title (single exchange)…');

    try {
      if (userPrompt.trim().isEmpty || aiResponse.trim().isEmpty) {
        return 'New Chat';
      }

      final geminiService = _buildService(session);
      final title = await geminiService.generateTitle(userPrompt, aiResponse);

      if (title.isEmpty || title.split(' ').length > 10) {
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

  // ── generateTitleFromHistory (anchor + recent window) ────────────────────

  /// Generates/refreshes a conversation title from a window of messages.
  ///
  /// [turns] is a flat list of serialised turns, oldest first, in the same
  /// "role: text" format used by [sendMessage]'s [history] parameter — e.g.
  /// the first exchange (anchor) followed by the most recent N messages.
  ///
  /// Returns null (rather than a fallback string) if generation fails, so
  /// the caller can decide to keep the existing title and retry later
  /// instead of overwriting a good title with "New Chat".
  Future<String?> generateTitleFromHistory(
    Session session,
    List<String> turns,
  ) async {
    session.log('Generating conversation title (${turns.length} turns)…');

    final parsed = _parseTurns(turns);
    if (parsed.isEmpty) return null;

    try {
      final geminiService = _buildService(session);
      final title = await geminiService.generateTitleFromTurns(parsed);

      if (title.isEmpty || title.split(' ').length > 10) {
        return null;
      }

      session.log('Title generated: "$title"');
      return title;
    } catch (e, stackTrace) {
      session.log(
        'Checkpoint title generation failed: $e\n$stackTrace',
        level: LogLevel.error,
      );
      return null;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

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

  List<ChatTurn> _parseTurns(List<String>? raw) {
    if (raw == null || raw.isEmpty) return const [];

    final turns = <ChatTurn>[];

    for (final entry in raw) {
      if (entry.toLowerCase().startsWith('user: ')) {
        turns.add(ChatTurn(role: 'user', text: entry.substring(6).trim()));
      } else if (entry.toLowerCase().startsWith('assistant: ')) {
        turns.add(ChatTurn(role: 'model', text: entry.substring(11).trim()));
      }
    }

    final maxEntries = _maxHistoryTurns * 2;
    if (turns.length > maxEntries) {
      return turns.sublist(turns.length - maxEntries);
    }
    return turns;
  }
}