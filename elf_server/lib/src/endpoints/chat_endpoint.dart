import 'package:elf_server/src/services/gemini_service.dart';
import 'package:serverpod/serverpod.dart';

class ChatEndpoint extends Endpoint {
  // ─────────────────────────────────────────────────────────────────────────
  // sendMessage
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> sendMessage(Session session, String message) async {
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    final preview = message.length > 50
        ? '${message.substring(0, 50)}...'
        : message;
    session.log('Chat message received: $preview');

    final geminiService = _buildService(session);
    final response = await geminiService.generateContent(message);

    session.log('AI response generated successfully');
    return response;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // generateTitle
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates a short (3–6 word) conversation title from the first exchange.
  ///
  /// Returns a fallback title string instead of throwing, so the Flutter app
  /// always receives a usable value.
  Future<String> generateTitle(
    Session session,
    String userPrompt,
    String aiResponse,
  ) async {
    session.log('Generating conversation title…');

    try {
      // Basic guard — if either input is empty we cannot generate a good title
      if (userPrompt.trim().isEmpty || aiResponse.trim().isEmpty) {
        session.log(
          'generateTitle: empty inputs, returning fallback',
          level: LogLevel.warning,
        );
        return 'New Chat';
      }

      final geminiService = _buildService(session);

      final title = await geminiService.generateTitle(
        userPrompt,
        aiResponse,
      );

      // Sanity-check: if Gemini returned something absurd, fall back
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
      // Log the full error for debugging but never propagate it —
      // a missing title must never crash the client.
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

  /// Reads the API key from passwords.yaml and returns a [GeminiService].
  /// Throws a clear exception if the key is missing so the log is actionable.
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
}