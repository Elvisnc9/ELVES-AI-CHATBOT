import 'package:elf_flutter/widgets/ChatScreem/actionButtons.dart';
import 'package:elf_flutter/widgets/ChatScreem/chatShimmer.dart';
import 'package:elf_flutter/widgets/ChatScreem/inputBar.dart';
import 'package:elf_flutter/widgets/ChatScreem/typingMarkdownanimation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

import 'package:elf_flutter/provider/chatState.dart';
import 'package:elf_flutter/provider/shellView.dart';
import 'package:elf_flutter/widgets/ChatScreem/typingdot_indicator.dart';
import 'package:elf_flutter/widgets/elvesDrawer.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CHAT SCREEN  (shell — owns the drawer only)
// ─────────────────────────────────────────────────────────────────────────────
class ChatScreen extends ConsumerStatefulWidget {
  final PageController pageController;
  final VoidCallback openDrawer;
 
  const ChatScreen({
    super.key,
    required this.pageController,
    required this.openDrawer,
  });
 
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatScreenState();
}
 
class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return ChatView(
      openDrawer: widget.openDrawer,
      pageController: widget.pageController,
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
//  CHAT VIEW
// ─────────────────────────────────────────────────────────────────────────────
 
class ChatView extends ConsumerStatefulWidget {
  final VoidCallback openDrawer;
  final PageController pageController;
 
  const ChatView({
    super.key,
    required this.openDrawer,
    required this.pageController,
  });
 
  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}
 
class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
 
  int _prevMessageCount = 0;
 
  // ── Edge-drag state ───────────────────────────────────────────────────────
  bool _trackingEdgeDrag = false;
  double _dragStartX = 0;
  double _pageOffsetAtDragStart = 1.0;
 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // if (mounted) _focusNode.requestFocus();
    });
  }
 
  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    // _focusNode.dispose();
    super.dispose();
  }
 
  void _smoothScrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }
 
  // ── Gesture handlers ──────────────────────────────────────────────────────
  // No left-edge threshold — any right-drag on the chat page peeks the drawer,
  // matching the ChatGPT iOS feel. Left drags are ignored.
 
  void _onHorizontalDragStart(DragStartDetails details) {
    _trackingEdgeDrag = true;
    _dragStartX = details.globalPosition.dx;
    _pageOffsetAtDragStart = widget.pageController.page ?? 1.0;
    _focusNode.unfocus();
  }
 
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_trackingEdgeDrag) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx - _dragStartX;
 
    // Only allow dragging right (toward drawer — decreasing page offset).
    if (dx <= 0) return;
 
    final newOffset = _pageOffsetAtDragStart - (dx / screenWidth);
    widget.pageController.jumpTo(newOffset.clamp(0.0, 1.0) * screenWidth);
  }
 
  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_trackingEdgeDrag) return;
    _trackingEdgeDrag = false;
 
    final velocity = details.primaryVelocity ?? 0;
    final drawerProgress = 1.0 - (widget.pageController.page ?? 1.0);
 
    // Snap open if fast rightward flick OR dragged more than 40% across.
    if (velocity > 300 || drawerProgress > 0.4) {
      widget.openDrawer();
    } else {
      widget.pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }
 
  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    final isLoadingConversation = ref.watch(
      chatProvider.select((s) => s.isLoadingConversation),
    );
    final messageCount = ref.watch(
      chatProvider.select((s) => s.messages.length),
    );
    final hint = ref.watch(
      chatProvider.select((s) => s.connectionHint),
    );
    final isLoading = ref.watch(
      chatProvider.select((s) => s.isLoading),
    );
 
    final hasMessages = messageCount > 0;
 
    if (messageCount != _prevMessageCount) {
      _prevMessageCount = messageCount;
      if (hasMessages) _smoothScrollToLatest();
    }
 
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Stack(
            children: [
              // ── Message list ───────────────────────────────────────
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: (hasMessages || isLoadingConversation) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  child: IgnorePointer(
                    ignoring: !hasMessages && !isLoadingConversation,
                    child: RepaintBoundary(
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black,
                              Colors.black,
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.30, 0.80, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isLoadingConversation
                              ? KeyedSubtree(
                                  key: const ValueKey('shimmer'),
                                  child: chatShimmerList(),
                                )
                              : KeyedSubtree(
                                  key: const ValueKey('messages'),
                                  child: _MessageList(
                                    scrollController: _scrollController,
                                    hint: hint,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
 
              // ── Welcome screen ─────────────────────────────────────
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: (hasMessages || isLoadingConversation) ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                  child: IgnorePointer(
                    ignoring: hasMessages || isLoadingConversation,
                    child: const _WelcomeContent(),
                  ),
                ),
              ),
 
              // ── Menu bar ──────────────────────────────────────────
              Positioned(
                top: 3.h,
                left: 0,
                right: 0,
                child: _MenuBar(openDrawer: widget.openDrawer),
              ),
 
              // ── Input bar ─────────────────────────────────────────
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: InputBar(
                  textController: _textController,
                  focusNode: _focusNode,
                  onScrollToLatest: _smoothScrollToLatest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 
 

// ─────────────────────────────────────────────────────────────────────────────
//  MESSAGE LIST  — isolated ConsumerWidget
// ─────────────────────────────────────────────────────────────────────────────

class _MessageList extends ConsumerWidget {
  final ScrollController scrollController;
  final String? hint;

  const _MessageList({
    required this.scrollController,
    required this.hint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only the list needs the full messages array
    final messages = ref.watch(chatProvider.select((s) => s.messages));
    final showHint = hint != null;
    final theme = Theme.of(context);

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      // addAutomaticKeepAlives: false — don't keep offscreen items alive
      addAutomaticKeepAlives: false,
      // addRepaintBoundaries: true is the default; each item gets its own layer
      padding: EdgeInsets.only(
        top: 20.h,
        bottom: 15.h,
        left: 12,
        right: 12,
      ),
      itemCount: messages.length + (showHint ? 1 : 0),
      itemBuilder: (context, index) {
        if (showHint && index == 1) {
          return _ConnectionHint(hint: hint!);
        }
        final msgIndex = (showHint && index > 1) ? index - 1 : index;
        final message = messages[msgIndex];

        // Each bubble is its own RepaintBoundary via _ChatBubble
        return _ChatBubble(
          key: ValueKey(message.id),
          message: message,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WELCOME CONTENT  — pure const widget, never rebuilds
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 20),
          child: Text(
            'How can I help Elvis ?',
            textAlign: TextAlign.center,
            style: textTheme.displayLarge?.copyWith(fontSize: 30.sp),
          ),
        ).animate().fadeIn().slideX(begin: 0.3),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MENU BAR  — isolated, only watches hasMessages
// ─────────────────────────────────────────────────────────────────────────────

class _MenuBar extends ConsumerWidget {
  final VoidCallback openDrawer;
  const _MenuBar({required this.openDrawer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMessages = ref.watch(
      chatProvider.select((s) => s.messages.isNotEmpty),
    );
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_outlined, size: 30),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              openDrawer();
            },
          ),
          const Spacer(),
          if (hasMessages) ...[
            Consumer(
              builder: (context, ref, _) {
                return GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    ref.read(chatProvider.notifier).startNewChat();
                  },
                  child: Image.asset(
                    'assets/new_chat.png',
                    color: theme.shadowColor,
                    width: 35,
                  ),
                );
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ref.read(shellViewProvider.notifier).state = ShellView.settings;
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  INPUT BAR  — isolated StatefulWidget + ConsumerWidget
//  Uses its own ValueNotifier for hasText — no setState on the parent
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
//  CHAT BUBBLE  — isolated, wrapped in RepaintBoundary
//  Stateful only for the isTypingComplete toggle
// ─────────────────────────────────────────────────────────────────────────────

class _ChatBubble extends ConsumerStatefulWidget {
  final ChatMessage message;
  const _ChatBubble({super.key, required this.message});

  @override
  ConsumerState<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends ConsumerState<_ChatBubble> {
  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final theme = Theme.of(context);
    final textTheme = Theme.of(context).textTheme;

    final isUser = message.role == MessageRole.user;
    final isAssistant = message.role == MessageRole.assistant;
    final isSystem = message.role == MessageRole.system;

    if (message.type == MessageType.typing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ScalingTypingDot(),
        ),
      );
    }

    if (message.isError) {
      return _SoftErrorBubble(message: message);
    }

    // RepaintBoundary isolates each bubble's paint from its neighbours
    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isUser ? 1.h : 0),
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(
                  maxWidth: isUser ? 75.w : 100.w,
                ),
                decoration: BoxDecoration(
                  color: isUser ? theme.canvasColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: isAssistant && !message.isTypingComplete
                    ? TypingMarkdown(
                        text: message.text,
                        textTheme: textTheme,
                        onCompleted: () {
                          if (mounted) {
                            setState(() => message.isTypingComplete = true);
                          }
                        },
                      )
                    : MarkdownBody(
                        data: message.text,
                        styleSheet: MarkdownStyleSheet(
                          p: textTheme.displayMedium,
                          strong: textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              if ((isAssistant || isSystem) &&
                  message.isTypingComplete &&
                  !message.isError) ...[
                const SizedBox(height: 3),
                _AssistantActionRow(message: message),
              ],
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 200.ms)
            .slideY(begin: 0.05, duration: 200.ms),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ASSISTANT ACTION ROW  — isolated
// ─────────────────────────────────────────────────────────────────────────────

class _AssistantActionRow extends ConsumerWidget {
  final ChatMessage message;
  const _AssistantActionRow({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Only watch the two fields needed here
    final firstMessageId = ref.watch(
      chatProvider.select((s) => s.messages.isNotEmpty ? s.messages.first.id : null),
    );
    final isGenerating = ref.watch(chatProvider.select((s) => s.isGenerating));
    final isLast = firstMessageId == message.id;

    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: 0.5,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LikeButton(),
            const SizedBox(width: 16),
            const DisLikeButton(),
            const SizedBox(width: 16),
            CopyIcon(text: message.text),
            const SizedBox(width: 16),
            Icon(Icons.share_outlined, size: 18, color: theme.shadowColor),
            if (isLast && !isGenerating) ...[
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () =>
                    ref.read(chatProvider.notifier).regenerateLastResponse(),
                child: Icon(Icons.refresh_rounded,
                    size: 18, color: theme.hintColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONNECTION HINT
// ─────────────────────────────────────────────────────────────────────────────

class _ConnectionHint extends StatelessWidget {
  final String hint;
  const _ConnectionHint({required this.hint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 14, bottom: 6, top: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hint,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.hintColor.withOpacity(0.45),
                fontWeight: FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SOFT ERROR BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _SoftErrorBubble extends StatelessWidget {
  final ChatMessage message;
  const _SoftErrorBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(maxWidth: double.infinity),
          decoration: BoxDecoration(
            color: theme.hintColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.hintColor.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: theme.hintColor.withOpacity(0.4),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.text,
                  style: textTheme.labelSmall?.copyWith(
                    color: theme.hintColor.withOpacity(0.6),
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

