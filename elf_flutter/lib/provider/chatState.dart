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

  /// Status hint shown below the typing dot.
  /// null when idle.
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

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageRole? role,
    MessageType? type,
    bool? isError,
    DateTime? timestamp,
    bool? isTypingComplete,
    bool? isLiked,
    bool? isCopied,
    bool? isRegenerating,
    bool? hasError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      role: role ?? this.role,
      type: type ?? this.type,
      isError: isError ?? this.isError,
      timestamp: timestamp ?? this.timestamp,
      isTypingComplete: isTypingComplete ?? this.isTypingComplete,
      isLiked: isLiked ?? this.isLiked,
      isCopied: isCopied ?? this.isCopied,
      isRegenerating: isRegenerating ?? this.isRegenerating,
      hasError: hasError ?? this.hasError,
    );
  }
}

// ─────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────

const int _historyWindowSize = 10;

/// How long to wait for the FIRST token before showing "Slow connection…"
const Duration _firstTokenSlowHint = Duration(seconds: 5);

/// How long to wait between tokens mid-stream before showing "Slow connection…"
const Duration _midStreamSlowHint = Duration(seconds: 8);

/// Hard timeout from the moment the user sends — covers the entire response.
const Duration _hardTimeout = Duration(seconds: 90);

// ─────────────────────────────────────────────
//  CHAT NOTIFIER
// ─────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  final Client client;
  final ChatDao chatDao;

  String? activeConversationId;
  bool _cancelled = false;

  /// Active stream subscription — cancelled when user taps Stop.
  StreamSubscription<String>? _streamSub;

  ChatNotifier(this.client, this.chatDao) : super(const ChatState());

  // ═══════════════════════════════════════════
  //  1. SEND MESSAGE
  // ═══════════════════════════════════════════

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    if (activeConversationId == null) {
      activeConversationId = DateTime.now().millisecondsSinceEpoch.toString();
      await chatDao.createConversation(
        ConversationsCompanion.insert(
          id: activeConversationId!,
          title: 'New Chat',
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

    state = state.copyWith(
      messages: [typingMsg, userMsg, ...state.messages],
      isLoading: true,
      isGenerating: true,
      connectionHint: 'Thinking…',
      error: null,
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

    await _streamAndAppendResponse(
      userMessage.trim(),
      saveToDb: true,
      runTitleGeneration: true,
    );
  }

  // ═══════════════════════════════════════════
  //  2. REGENERATE
  // ═══════════════════════════════════════════

  Future<void> regenerateLastResponse() async {
    final lastUserMsg = state.messages.firstWhere(
      (m) => m.role == MessageRole.user && m.type == MessageType.normal,
      orElse: () => throw Exception('No user message to regenerate from'),
    );

    final lastUserIndex = state.messages.indexOf(lastUserMsg);
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
      connectionHint: 'Thinking…',
    );

    await _streamAndAppendResponse(
      lastUserMsg.text,
      saveToDb: false,
      runTitleGeneration: false,
    );
  }

  // ═══════════════════════════════════════════
  //  3. EDIT & RESEND
  // ═══════════════════════════════════════════

  Future<void> editAndResend(String messageId, String newText) async {
    if (newText.trim().isEmpty) return;

    final msgs = state.messages;
    final editedIndex = msgs.indexWhere((m) => m.id == messageId);
    if (editedIndex == -1) return;

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
      connectionHint: 'Searching Web',
    );

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

    await _streamAndAppendResponse(
      newText.trim(),
      saveToDb: true,
      runTitleGeneration: false,
    );
  }

  // ═══════════════════════════════════════════
  //  CORE: STREAM + APPEND RESPONSE
  // ═══════════════════════════════════════════

  Future<void> _streamAndAppendResponse(
    String userMessage, {
    required bool saveToDb,
    required bool runTitleGeneration,
  }) async {
    _cancelled = false;

    final history = _buildHistory();

    // The streaming assistant message starts empty and grows with each token.
    // We insert it immediately so the UI can start rendering without a typing dot.
    final aiMsgId = 'ai-${DateTime.now().millisecondsSinceEpoch}';
    final aiMsg = ChatMessage(
      id: aiMsgId,
      text: '',
      role: MessageRole.assistant,
      isTypingComplete: false,
    );

    // Accumulated response text
    final responseBuffer = StringBuffer();

    // Whether we have received at least one token
    bool firstTokenReceived = false;

    // ── Timers ──────────────────────────────────────────────────────────────

    // Fires if first token takes too long
    Timer? firstTokenTimer;
    // Fires if no token arrives for a while mid-stream
    Timer? midStreamTimer;
    // Hard cutoff for the entire response
    Timer? hardTimeoutTimer;
    // Completer that fires when hard timeout hits
    final hardTimeoutCompleter = Completer<void>();

    void resetMidStreamTimer() {
      midStreamTimer?.cancel();
      midStreamTimer = Timer(_midStreamSlowHint, () {
        if (!_cancelled && mounted) {
          state = state.copyWith(
            connectionHint: 'Slow connection ',
          );
        }
      });
    }

    void cancelAllTimers() {
      firstTokenTimer?.cancel();
      midStreamTimer?.cancel();
      hardTimeoutTimer?.cancel();
    }

    firstTokenTimer = Timer(_firstTokenSlowHint, () {
      if (!firstTokenReceived && !_cancelled && mounted) {
        state = state.copyWith(
          connectionHint: 'Slow connection… waiting for response',
        );
      }
    });

    hardTimeoutTimer = Timer(_hardTimeout, () {
      if (!hardTimeoutCompleter.isCompleted) {
        hardTimeoutCompleter.completeError(
          Exception('Request timed out. Please try again.'),
        );
      }
    });

    // ── Helper: update the live AI message in state ──────────────────────

    void pushTokenToState(String newText) {
      if (!mounted || _cancelled) return;

      final currentMessages = [...state.messages];
      // Remove typing bubble if it's still there
      currentMessages.removeWhere((m) => m.type == MessageType.typing);

      final existingIndex =
          currentMessages.indexWhere((m) => m.id == aiMsgId);

      if (existingIndex == -1) {
        // First token: insert the ai message bubble
        state = state.copyWith(
          messages: [
            aiMsg.copyWith(text: newText, isTypingComplete: false),
            ...currentMessages,
          ],
          isLoading: false, // input bar re-enables
          isGenerating: true, // stop button still visible
          clearHint: true,
        );
      } else {
        // Subsequent tokens: update in place
        currentMessages[existingIndex] =
            currentMessages[existingIndex].copyWith(text: newText);
        state = state.copyWith(
          messages: currentMessages,
          isGenerating: true,
          clearHint: true,
        );
      }
    }

    // ── Subscribe to the stream ───────────────────────────────────────────

    final streamCompleter = Completer<void>();

    _streamSub = client.chat
        .sendMessage(userMessage, history: history)
        .listen(
      (chunk) {
        if (_cancelled) return;

        if (!firstTokenReceived) {
          firstTokenReceived = true;
          firstTokenTimer?.cancel();
        }

        responseBuffer.write(chunk);
        resetMidStreamTimer();
        pushTokenToState(responseBuffer.toString());
      },
      onError: (Object error, StackTrace stack) {
        cancelAllTimers();
        if (!streamCompleter.isCompleted) {
          streamCompleter.completeError(error, stack);
        }
      },
      onDone: () {
        cancelAllTimers();
        if (!streamCompleter.isCompleted) {
          streamCompleter.complete();
        }
      },
      cancelOnError: true,
    );

    // ── Race: stream finishes vs hard timeout ────────────────────────────

    try {
      await Future.any([
        streamCompleter.future,
        hardTimeoutCompleter.future,
      ]);

      if (_cancelled) return;

      // Stream finished successfully
      final fullResponse = responseBuffer.toString();

      // Mark the message as typing-complete (triggers action row)
      if (mounted) {
        final currentMessages = [...state.messages];
        final idx = currentMessages.indexWhere((m) => m.id == aiMsgId);
        if (idx != -1) {
          currentMessages[idx] =
              currentMessages[idx].copyWith(isTypingComplete: true);
          state = state.copyWith(
            messages: currentMessages,
            isGenerating: false,
            clearHint: true,
          );
        }
      }

      // Persist to DB
      if (saveToDb && activeConversationId != null && fullResponse.isNotEmpty) {
        await chatDao.saveMessage(
          MessagesCompanion.insert(
            id: aiMsgId,
            conversationId: activeConversationId!,
            role: 'assistant',
            content: fullResponse,
            createdAt: DateTime.now(),
          ),
        );
        await chatDao.touchConversation(activeConversationId!);
      }

      // Auto-generate title after first exchange
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
              fullResponse,
            );
            await chatDao.updateConversationTitle(
                activeConversationId!, title);
          }
        } catch (_) {
          // Title generation is best-effort — never surface to user
        }
      }
    } catch (error) {
      cancelAllTimers();
      await _streamSub?.cancel();
      _streamSub = null;

      if (_cancelled) return;
      if (!mounted) return;

      final appError = mapError(error);

      // Remove typing bubble and the (possibly partial) ai message
      final updatedMessages = [...state.messages];
      updatedMessages.removeWhere(
        (m) => m.type == MessageType.typing || m.id == aiMsgId,
      );

      final errorMsg = ChatMessage(
        id: 'err-${DateTime.now().millisecondsSinceEpoch}',
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

    _streamSub = null;
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
    await _streamSub?.cancel();
    _streamSub = null;
    _cancelled = true;
    activeConversationId = null;
    state = const ChatState();
  }

  Future<void> loadConversation(String conversationId) async {
    await _streamSub?.cancel();
    _streamSub = null;
    _cancelled = true;

    state = state.copyWith(
      isLoadingConversation: true,
      messages: [],
    );

    await Future.delayed(const Duration(milliseconds: 300));

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
      await _streamSub?.cancel();
      _streamSub = null;
      activeConversationId = null;
      state = const ChatState();
    }
  }

  void clearChat() => state = const ChatState();
  void clearError() => state = state.copyWith(error: null);

  void stopGeneration() {
    _cancelled = true;
    _streamSub?.cancel();
    _streamSub = null;

    final updatedMessages = [...state.messages];
    updatedMessages.removeWhere((m) => m.type == MessageType.typing);

    // Mark the partial message as complete so action row appears
    final partialIndex = updatedMessages.indexWhere(
      (m) => m.role == MessageRole.assistant && !m.isTypingComplete,
    );
    if (partialIndex != -1) {
      updatedMessages[partialIndex] =
          updatedMessages[partialIndex].copyWith(isTypingComplete: true);
    }

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

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
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
final inputAutofocusProvider = StateProvider<bool>((ref) => true);