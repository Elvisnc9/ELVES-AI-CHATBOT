import 'package:elf_server/src/services/gemini_service.dart';
import 'package:serverpod/serverpod.dart';



class ChatEndpoint extends Endpoint {
  
  Future<String> sendMessage(Session session, String message) async {
    try {
      
      if (message.trim().isEmpty) {
        throw Exception('Message cannot be empty');
      }

      
      final preview = message.length > 50 
          ? '${message.substring(0, 50)}...' 
          : message;
      session.log('Chat message received: $preview');

      
      final apiKey = session.passwords['geminiApiKey'];
      
      if (apiKey == null || apiKey.isEmpty) {
        session.log(
          'Gemini API key not found in passwords.yaml',
          level: LogLevel.error,
        );
        throw Exception('Gemini API key not configured');
      }

      
      final geminiService = GeminiService(apiKey: apiKey);
      final response = await geminiService.generateContent(message);

      session.log('AI response generated successfully');
      return response;

    } catch (e, stackTrace) {
      session.log(
        'Error in sendMessage: $e',
        level: LogLevel.error,
      );
      session.log(
        'Stack trace: $stackTrace',
        level: LogLevel.error,
      );
      
      
      if (e.toString().contains('API key') || 
          e.toString().contains('configured')) {
        rethrow;
      }
      
      
      throw Exception('Failed to generate AI response. Please try again.');
    }
  }

  Future<String> generateTitle(
  Session session,
  String userPrompt,
  String aiResponse,
) async {
  try {
    final apiKey = session.passwords['geminiApiKey'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API key not configured');
    }

    final geminiService = GeminiService(apiKey: apiKey);

    final title = await geminiService.generateTitle(
      userPrompt,
      aiResponse,
    );

    return title.trim();

  } catch (e) {
    session.log(
      'Title generation failed: $e',
      level: LogLevel.error,
    );

    return 'New Chat';
  }
}

}