import 'dart:async';

import 'package:elf_flutter/data/database/chat_dao.dart';
import 'package:elf_flutter/data/database/chat_database.dart';
import 'package:elf_flutter/provider/chat_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elf_client/elf_client.dart';
import 'package:elf_flutter/core/app_errors/error_mapper.dart';
import 'package:elf_flutter/main.dart';

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
  final bool isLoadingConversation;
  final String? error;
  final bool isGenerating;

  /// Shown above the typing dot when connection is slow.
  /// Null when connection is fine or request is done.
  final String? connectionHint;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingConversation = false,
    this.error,
    this.isGenerating = false,
    this.connectionHint,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isLoadingConversation,
    bool? isGenerating,
    String? error,
    String? connectionHint,
    bool clearHint = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingConversation:
          isLoadingConversation ?? this.isLoadingConversation,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      connectionHint: clearHint ? null : (connectionHint ?? this.connectionHint),
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final MessageRole role;
  final MessageType type;
  final DateTime timestamp;
  bool isTypingComplete;
  final bool isError;
  final bool? isLiked;
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

const int _historyWindowSize = 10;

// How long before we surface the "slow connection" hint
const Duration _slowHintDelay = Duration(seconds: 8);

// How long before we give up entirely
const Duration _hardTimeout = Duration(seconds: 20);

class ChatNotifier extends StateNotifier<ChatState> {
  final Client client;
  final ChatDao chatDao;
  String? activeConversationId;

  ChatNotifier(this.client, this.chatDao) : super(const ChatState());

  // ── Send message ────────────────────────────────────────────────────────

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    // Create conversation if needed
    if (activeConversationId == null) {
      activeConversationId = DateTime.now().millisecondsSinceEpoch.toString();
      await chatDao.createConversation(
        ConversationsCompanion.insert(
          id: activeConversationId!,
          title: "New Chat",
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        ),
      );
    }

    final history = _buildHistory();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: userMessage.trim(),
      role: MessageRole.user,
    );

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
      clearHint: false,
    );

    await chatDao.saveMessage(
      MessagesCompanion.insert(
        id: userMsg.id,
        conversationId: activeConversationId!,
        role: 'user',
        content: userMsg.text,
        createdAt: DateTime.now(),
      ),
    );

    // ── Timers ────────────────────────────────────────────────────────────

    Timer? hintTimer;
    Timer? hardTimer;
    bool completed = false;

    // 5s → surface slow connection hint above the typing dot
    hintTimer = Timer(_slowHintDelay, () {
      if (!completed && mounted) {
        state = state.copyWith(
          connectionHint: "Slow connection… still working on it",
        );
      }
    });

    // 30s → cancel and surface a timeout error
    final timeoutCompleter = Completer<void>();
    hardTimer = Timer(_hardTimeout, () {
      if (!completed) {
        timeoutCompleter.completeError(
          Exception('Request timed out after 30 seconds'),
        );
      }
    });

    // ── Race the API call against the hard timeout ────────────────────────

    try {
      final aiResponse = await Future.any([
        client.chat.sendMessage(userMessage, history: history),
        timeoutCompleter.future.then((_) => ''), // never resolves, only errors
      ]);

      completed = true;
      hintTimer.cancel();
      hardTimer.cancel();

      // Remove typing bubble
      final updatedMessages = [...state.messages];
      updatedMessages.removeWhere((m) => m.type == MessageType.typing);

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
        clearHint: true,
      );

      await chatDao.saveMessage(
        MessagesCompanion.insert(
          id: aiMsg.id,
          conversationId: activeConversationId!,
          role: 'assistant',
          content: aiResponse,
          createdAt: DateTime.now(),
        ),
      );

      // Auto-title on first exchange
      final messages = await chatDao.getMessages(activeConversationId!);
      final userMessages = messages.where((m) => m.role == 'user').toList();

      if (userMessages.length == 1) {
        try {
          await Future<void>.delayed(const Duration(seconds: 2));
          final title = await client.chat.generateTitle(
            userMessages.first.content,
            aiResponse,
          );
          await chatDao.updateConversationTitle(activeConversationId!, title);
        } catch (_) {}
      }
    } catch (e) {
      completed = true;
      hintTimer.cancel();
      hardTimer.cancel();

      // Clean up conversation on first message failure
      if (activeConversationId != null) {
        try {
          await chatDao.deleteConversation(activeConversationId!);
        } catch (_) {}
        activeConversationId = null;
      }

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
        isGenerating: false,
        clearHint: true,
      );
    }
  }

  // ── History builder ──────────────────────────────────────────────────────

  List<String> _buildHistory() {
    final chronological = state.messages.reversed.toList();

    final real = chronological.where(
      (m) =>
          m.type == MessageType.normal &&
          !m.isError &&
          (m.role == MessageRole.user || m.role == MessageRole.assistant),
    );

    final serialised = real.map((m) {
      final prefix = m.role == MessageRole.user ? 'user' : 'assistant';
      return '$prefix: ${m.text}';
    }).toList();

    final maxEntries = _historyWindowSize * 2;
    if (serialised.length > maxEntries) {
      return serialised.sublist(serialised.length - maxEntries);
    }
    return serialised;
  }

  // ── Conversation management ──────────────────────────────────────────────

  Future<void> startNewChat() async {
    activeConversationId = null;
    state = const ChatState();
  }

  Future<void> loadConversation(String conversationId) async {
    state = state.copyWith(
      isLoadingConversation: true,
      messages: [],
    );

    await Future.delayed(const Duration(seconds: 1));

    final messages = await chatDao.getMessages(conversationId);

    final chatMessages = messages.map((m) {
      return ChatMessage(
        id: m.id,
        text: m.content,
        role: m.role == 'user' ? MessageRole.user : MessageRole.assistant,
        timestamp: m.createdAt,
        isTypingComplete: true,
      );
    }).toList();

    activeConversationId = conversationId;

    state = state.copyWith(
      messages: chatMessages.reversed.toList(),
      isLoadingConversation: false,
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
    state = state.copyWith(
      isLoading: false,
      isGenerating: false,
      isLoadingConversation: false,
      clearHint: true,
    );
  }

  int get messageCount => state.messages.length;
  bool get isEmpty => state.messages.isEmpty;
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final db = ref.watch(chatDatabaseProvider);
  return ChatNotifier(client, ChatDao(db));
});

final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final notifier = ref.watch(chatProvider.notifier);
  return notifier.watchConversations();
});

final chatLoadingProvider = StateProvider<bool>((ref) => false);