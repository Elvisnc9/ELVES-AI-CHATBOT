import 'package:elf_flutter/data/database/chat_dao.dart';
import 'package:elf_flutter/data/database/chat_database.dart';
import 'package:elf_flutter/provider/chat_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elf_client/elf_client.dart';
import 'package:elf_flutter/core/app_errors/error_mapper.dart';
import 'package:elf_flutter/main.dart';

final clientProvider = Provider<Client>((ref) {
  return client;
});

// Simple session manager (no auth in Ghost Mode)
class SessionManager extends AuthenticationKeyManager {
  @override
  Future<String?> get() async => null;

  @override
  Future<void> put(String key) async {}

  @override
  Future<void> remove() async {}

  @override
  Future<String?> toHeaderValue(String? key) async {
    // Return null or the header value as needed for your use case
    return null;
  }
}

// ==================== CHAT STATE MODEL ====================

enum MessageRole {
  user,
  assistant,
  system,
}

enum MessageType {
  normal,
  typing,
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool isGenerating;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isGenerating = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isGenerating,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

// ==================== CHAT MESSAGE MODEL ====================

class ChatMessage {
  final String id;
  final String text;
  final MessageRole role;
  final MessageType type;
  final DateTime timestamp;
  bool isTypingComplete;
  final bool isError;

  // 🔥 Future interaction states
  final bool? isLiked; // null = not voted
  final bool isCopied;
  final bool isRegenerating;
  final bool hasError;

  ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    this.type = MessageType.normal,
    this.isError = false,
    DateTime? timestamp,
    this.isLiked,
    this.isTypingComplete = false,
    this.isCopied = false,
    this.isRegenerating = false,
    this.hasError = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ==================== CHAT NOTIFIER ====================

class ChatNotifier extends StateNotifier<ChatState> {
  final Client client;
  final ChatDao chatDao;

  String? activeConversationId;

  ChatNotifier(this.client, this.chatDao) : super(const ChatState());

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    /// CREATE CONVERSATION ONLY WHEN FIRST MESSAGE ARRIVES
    if (activeConversationId == null) {
      activeConversationId =
          DateTime.now().millisecondsSinceEpoch.toString();

      await chatDao.createConversation(
        ConversationsCompanion.insert(
          id: activeConversationId!,
          title: "New Chat",
          createdAt: DateTime.now(),
        ),
      );
    }

    /// USER MESSAGE
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: userMessage.trim(),
      role: MessageRole.user,
    );

    /// TYPING INDICATOR
    final typingMsg = ChatMessage(
      id: 'typing-${DateTime.now().millisecondsSinceEpoch}',
      text: '',
      role: MessageRole.assistant,
      type: MessageType.typing,
    );

    state = state.copyWith(
      messages: [typingMsg, userMsg, ...state.messages],
      isLoading: true,
      isGenerating: true,
      error: null,
    );

    /// SAVE USER MESSAGE
    await chatDao.saveMessage(
      MessagesCompanion.insert(
        id: userMsg.id,
        conversationId: activeConversationId!,
        role: 'user',
        content: userMsg.text,
        createdAt: DateTime.now(),
      ),
    );

    try {
      /// CALL AI
      final aiResponse = await client.chat.sendMessage(userMessage);

      /// REMOVE TYPING
      final updatedMessages = [...state.messages];
      updatedMessages.removeWhere((m) => m.type == MessageType.typing);

      /// AI MESSAGE
      final aiMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: aiResponse,
        role: MessageRole.assistant,
        isTypingComplete: false,
      );

      state = state.copyWith(
        messages: [aiMsg, ...updatedMessages],
        isLoading: false,
        isGenerating: false,
      );

      /// SAVE AI MESSAGE
      await chatDao.saveMessage(
        MessagesCompanion.insert(
          id: aiMsg.id,
          conversationId: activeConversationId!,
          role: 'assistant',
          content: aiResponse,
          createdAt: DateTime.now(),
        ),
      );

      /// CHECK MESSAGE COUNT
      final messages =
          await chatDao.getMessages(activeConversationId!);

      final userMessages =
          messages.where((m) => m.role == 'user').toList();

      /// GENERATE TITLE AFTER FIRST PROMPT
      /// GENERATE TITLE AFTER FIRST PROMPT
if (userMessages.length == 1) {
        try {
          // 2-second spacing so this request doesn't land in the same
          // per-minute window as the sendMessage call above.
          // The server-side retry handles any remaining rate-limit bursts.
          await Future<void>.delayed(const Duration(seconds: 2));

          final title = await client.chat.generateTitle(
            userMessages.first.content,
            aiResponse,
          );

          await chatDao.updateConversationTitle(
            activeConversationId!,
            title,
          );
        } catch (_) {
          await chatDao.updateConversationTitle(
            activeConversationId!,
            'New Chat',
          );
        }
      }






    } catch (e) {
      final appError = mapError(e);

      final updatedMessages = [...state.messages];
      updatedMessages.removeWhere((m) => m.type == MessageType.typing);

      final errorMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: appError.message,
        role: MessageRole.assistant,
        isError: true,
      );

      state = state.copyWith(
        messages: [errorMsg, ...updatedMessages],
        isLoading: false,
      );
    }
  }

  /// NEW CHAT (DO NOT CREATE CONVERSATION YET)
  Future<void> startNewChat() async {
    activeConversationId = null;
    state = const ChatState();
  }

 

  Future<void> loadConversation(String conversationId) async {
  state = state.copyWith(isLoading: true);

  /// artificial shimmer delay
  await Future.delayed(const Duration(seconds: 1));

  final messages = await chatDao.getMessages(conversationId);

  final chatMessages = messages.map((m) {
    return ChatMessage(
      id: m.id,
      text: m.content,
      role: m.role == 'user'
          ? MessageRole.user
          : MessageRole.assistant,
      timestamp: m.createdAt,
      isTypingComplete: true,
    );
  }).toList();

  activeConversationId = conversationId;

  state = state.copyWith(
    messages: chatMessages.reversed.toList(),
    isLoading: false,
  );
}


  Stream<List<Conversation>> watchConversations() {
    return chatDao.watchAllConversations();
  }

  Future<void> deleteConversation(String id) async {
    await chatDao.deleteConversation(id);

    if (activeConversationId == id) {
      activeConversationId = null;
      state = const ChatState();
    }
  }

  void clearChat() {
    state = const ChatState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void stopGeneration() {
    state = state.copyWith(isLoading: false);
  }

  int get messageCount => state.messages.length;

  bool get isEmpty => state.messages.isEmpty;
}


// ==================== PROVIDER ====================

/// Main chat provider - use this in your UI
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final client = ref.watch(clientProvider);
  final db = ref.watch(chatDatabaseProvider);
  return ChatNotifier(client, ChatDao(db));
});

final conversationsProvider =
    StreamProvider<List<Conversation>>((ref) {
  final notifier = ref.watch(chatProvider.notifier);
  return notifier.watchConversations();
});
final chatLoadingProvider = StateProvider<bool>((ref) => false);