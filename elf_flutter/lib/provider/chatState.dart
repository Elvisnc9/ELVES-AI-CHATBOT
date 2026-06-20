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

// ─────────────────────────────────────────────
//  CHAT STATE
// ─────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isLoadingConversation;
  final String? error;
  final bool isGenerating;

  /// "Thinking…" immediately, swaps to "Slow connection…" at 5s.
  /// Null when idle or request is done.
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
      connectionHint:
          clearHint ? null : (connectionHint ?? this.connectionHint),
    );
  }
}

// ─────────────────────────────────────────────
//  CHAT MESSAGE
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────

const int _historyWindowSize = 10;
const Duration _slowHintDelay = Duration(seconds: 10);
const Duration _hardTimeout = Duration(seconds: 40);

// ─────────────────────────────────────────────
//  CHAT NOTIFIER
// ─────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  final Client client;
  final ChatDao chatDao;
  String? activeConversationId;
   bool _cancelled = false;

  ChatNotifier(this.client, this.chatDao) : super(const ChatState());

  // ═══════════════════════════════════════════
  //  1. SEND MESSAGE  (new user prompt)
  // ═══════════════════════════════════════════

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    // Create a new conversation in DB if this is the first message
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

    // Show user message + typing dot 
    state = state.copyWith(
      messages: [typingMsg, userMsg, ...state.messages],
      isLoading: true,
      isGenerating: true,
      error: null,
      clearHint: false,
    );

    // Persist user message to DB
    await chatDao.saveMessage(
      MessagesCompanion.insert(
        id: userMsg.id,
        conversationId: activeConversationId!,
        role: 'user',
        content: userMsg.text,
        createdAt: DateTime.now(),
      ),
    );

    // Fetch AI response — timers + error handling all live inside here
    await _fetchAndAppendResponse(
      userMessage.trim(),
      saveToDb: true,
      runTitleGeneration: true,
    );
  }

  // ═══════════════════════════════════════════
  //  2. REGENERATE  (redo last assistant reply)
  // ═══════════════════════════════════════════

  Future<void> regenerateLastResponse() async {
    // Find the most recent user message
    final lastUserMsg = state.messages.firstWhere(
      (m) => m.role == MessageRole.user && m.type == MessageType.normal,
      orElse: () => throw Exception('No user message to regenerate from'),
    );

    final lastUserIndex = state.messages.indexOf(lastUserMsg);

    // Keep user message + everything older, drop last assistant reply
    final trimmed = state.messages.sublist(lastUserIndex);

    final typingMsg = ChatMessage(
      id: 'typing-${DateTime.now().millisecondsSinceEpoch}',
      text: '',
      role: MessageRole.assistant,
      type: MessageType.typing,
    );

    state = state.copyWith(
      messages: [typingMsg, ...trimmed],
      isLoading: true,
      isGenerating: true,
      connectionHint: "Thinking…",
      clearHint: false,
    );

    await _fetchAndAppendResponse(
      lastUserMsg.text,
      saveToDb: false,
      runTitleGeneration: false,
    );
  }

  // ═══════════════════════════════════════════
  //  3. EDIT & RESEND  (inline edit a user msg)
  // ═══════════════════════════════════════════

  Future<void> editAndResend(String messageId, String newText) async {
    if (newText.trim().isEmpty) return;

    final msgs = state.messages;
    final editedIndex = msgs.indexWhere((m) => m.id == messageId);
    if (editedIndex == -1) return;

    // Keep everything older than the edited message, discard newer
    final older = msgs.sublist(editedIndex + 1);

    final newUserMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: newText.trim(),
      role: MessageRole.user,
    );

    final typingMsg = ChatMessage(
      id: 'typing-${DateTime.now().millisecondsSinceEpoch}',
      text: '',
      role: MessageRole.assistant,
      type: MessageType.typing,
    );

    state = state.copyWith(
      messages: [typingMsg, newUserMsg, ...older],
      isLoading: true,
      isGenerating: true,
      connectionHint: "Thinking…",
      clearHint: false,
    );

    // Persist the edited message to DB
    if (activeConversationId != null) {
      await chatDao.saveMessage(
        MessagesCompanion.insert(
          id: newUserMsg.id,
          conversationId: activeConversationId!,
          role: 'user',
          content: newUserMsg.text,
          createdAt: DateTime.now(),
        ),
      );
    }

    await _fetchAndAppendResponse(
      newText.trim(),
      saveToDb: true,
      runTitleGeneration: false,
    );
  }

  // ═══════════════════════════════════════════
  //  CORE: FETCH + APPEND AI RESPONSE
  //  Shared by sendMessage / regenerate / editAndResend
  // ═══════════════════════════════════════════

  Future<void> _fetchAndAppendResponse(
    String userMessage, {
    required bool saveToDb,
    required bool runTitleGeneration,
  }) async {
    _cancelled = false;
    final history = _buildHistory();
    bool completed = false;

    // 5s → swap hint to "Slow connection…"
    final hintTimer = Timer(_slowHintDelay, () {
      if (!completed && !_cancelled && mounted) {
        state = state.copyWith(
          connectionHint: "Slow connection… still working on it",
        );
      }
    });

    // 30s → hard timeout via completer
    final timeoutCompleter = Completer<void>();
    final hardTimer = Timer(_hardTimeout, () {
      if (!completed) {
        timeoutCompleter.completeError(
          Exception('Request timed out after 30 seconds'),
        );
      }
    });

    try {
      // Race API call vs hard timeout
      final aiResponse = await Future.any([
        client.chat.sendMessage(userMessage, history: history),
        timeoutCompleter.future.then((_) => ''), // only ever errors, never resolves
      ]);

      completed = true;
      hintTimer.cancel();
      hardTimer.cancel();

if (_cancelled) return;
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

      // Persist AI response to DB
      if (saveToDb && activeConversationId != null) {
        await chatDao.saveMessage(
          MessagesCompanion.insert(
            id: aiMsg.id,
            conversationId: activeConversationId!,
            role: 'assistant',
            content: aiResponse,
            createdAt: DateTime.now(),
          ),
        );
      }

      // Auto-generate conversation title after first exchange
      if (runTitleGeneration && activeConversationId != null) {
        try {
          final dbMessages =
              await chatDao.getMessages(activeConversationId!);
          final userMessages =
              dbMessages.where((m) => m.role == 'user').toList();

          if (userMessages.length == 1) {
            await Future<void>.delayed(const Duration(seconds: 2));
            final title = await client.chat.generateTitle(
              userMessages.first.content,
              aiResponse,
            );
            await chatDao.updateConversationTitle(
                activeConversationId!, title);
          }
        } catch (_) {}
      }
   } catch (e) {
  completed = true;
  hintTimer.cancel();
  hardTimer.cancel();

if (_cancelled) return;


  final appError = mapError(e);

  // Remove typing bubble but keep all previous messages intact
  final updatedMessages = [...state.messages];
  updatedMessages.removeWhere((m) => m.type == MessageType.typing);

  final errorMsg = ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    text: appError.message,
    role: MessageRole.assistant,
    isError: true,
  );

  // Return to a fully usable state — user can retry
  state = state.copyWith(
    messages: [errorMsg, ...updatedMessages],
    isLoading: false,
    isGenerating: false,
    clearHint: true,
  );
}
  }

  // ═══════════════════════════════════════════
  //  HISTORY BUILDER
  // ═══════════════════════════════════════════

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

  // ═══════════════════════════════════════════
  //  CONVERSATION MANAGEMENT
  // ═══════════════════════════════════════════

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

  void clearChat() => state = const ChatState();

  void clearError() => state = state.copyWith(error: null);

  void stopGeneration() {
    _cancelled = true;
    final updatedMessages = [...state.messages];
  updatedMessages.removeWhere((m) => m.type == MessageType.typing);
    state = state.copyWith(
      messages: updatedMessages,
      isLoading: false,
      isGenerating: false,
      isLoadingConversation: false,
      clearHint: true,
    );
  }

  int get messageCount => state.messages.length;
  bool get isEmpty => state.messages.isEmpty;
}

// ─────────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────────

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final db = ref.watch(chatDatabaseProvider);
  return ChatNotifier(client, ChatDao(db));
});

final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final notifier = ref.watch(chatProvider.notifier);
  return notifier.watchConversations();
});

final chatLoadingProvider = StateProvider<bool>((ref) => false);

// anywhere, e.g. in chatState.dart or its own file
final inputAutofocusProvider = StateProvider<bool>((ref) => true);