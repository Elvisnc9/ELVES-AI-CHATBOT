import 'package:elf_flutter/widgets/ChatScreem/chatShimmer.dart';
import 'package:elf_flutter/widgets/ChatScreem/typingMarkdownanimation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

import 'package:elf_flutter/provider/chatState.dart';
import 'package:elf_flutter/provider/shellView.dart';
import 'package:elf_flutter/widgets/ChatScreem/chatModels.dart';
import 'package:elf_flutter/widgets/ChatScreem/typingdot_indicator.dart';
import 'package:elf_flutter/widgets/elvesDrawer.dart';


class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ElvesDrawerController _drawerController = ElvesDrawerController();

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Main chat view ─────────────────────────────────────────────
        ChatView(drawerController: _drawerController),

        // ── Drawer overlay (sits above chat, below nothing) ────────────
        ElvesDrawerOverlay(controller: _drawerController),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
//  CHAT VIEW
// ─────────────────────────────────────────────────────────────────────────────

class ChatView extends ConsumerStatefulWidget {
  final ElvesDrawerController drawerController;
  const ChatView({super.key, required this.drawerController});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  int _prevMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }


void _smoothScrollToLatest() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || !_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,  // ← feels natural, like GPT
    );
  });}

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  TextTheme get textTheme => Theme.of(context).textTheme;
  ChatState get chatState => ref.watch(chatProvider);
  List<ChatMessage> get messages => chatState.messages;
  bool get hasMessages => messages.isNotEmpty;
  ThemeData get theme => Theme.of(context);
  

  @override
  Widget build(BuildContext context) {
   final currentCount = messages.length;

  if (currentCount != _prevMessageCount) {
    _prevMessageCount = currentCount;
    if (hasMessages) _smoothScrollToLatest();
  }
  // ... rest of build




    final isLoadingConversation = chatState.isLoadingConversation;
    final hint = chatState.connectionHint;
   final showHint = hint != null;
   final itemCount = messages.length + (showHint ? 1 : 0);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox.expand(
        child: Stack(
          children: [
            // ── Message list ───────────────────────────────────────────
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
                                child: ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  padding: EdgeInsets.only(
                                    top: 20.h,
                                    bottom: 15.h,
                                    left: 12,
                                    right: 12,
                                  ),
                                  itemCount: messages.length + (showHint ? 1 : 0),
                                itemBuilder: (context, index) {
     // index 0 is the TOP of the reversed list = most recent
     // Show hint above the typing dot (index 0 slot)
     if (showHint && index == 1) {
       return _connectionHint(hint, theme);  // ← hint row
     }
      final msgIndex = (showHint && index > 1) ? index - 1 : index;
     final message = messages[msgIndex];
     return _chatBubble(message, key: ValueKey(message.id));
//    }
                                  },
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Welcome screen ─────────────────────────────────────────
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: (hasMessages || isLoadingConversation) ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
                child: IgnorePointer(
                  ignoring: hasMessages || isLoadingConversation,
                  child: _buildWelcomeContent(theme),
                ),
              ),
            ),

            // ── Menu bar ──────────────────────────────────────────────
            Positioned(
              top: 3.h,
              left: 0,
              right: 0,
              child: _buildMenuBar(theme),
            ),

            // ── Input bar ─────────────────────────────────────────────
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: _buildInputBar(theme, chatState.isLoading),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeContent(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 20),
          child: Text(
            'How can I help ?',
            textAlign: TextAlign.center,
            style: textTheme.displayLarge?.copyWith(fontSize: 32.sp),
          ),
        ).animate().fadeIn().slideX(begin: 0.3),
        PremiumFloatingChips(),
      ],
    );
  }

Widget _buildInputBar(ThemeData theme, bool isLoading) {
  final bool isTyping = messages.any(
    (m) => m.role == MessageRole.assistant && !m.isTypingComplete,
  );

  final isGenerating = chatState.isGenerating;
  final isLoadingConversation = chatState.isLoadingConversation;
  final bool canSend = !isGenerating;

  final bool hasText = _textController.text.trim().isNotEmpty;

  final bool showVoiceButton =
      ref.watch(chatProvider.notifier).activeConversationId == null &&
      !isLoading &&
      !hasText;

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(1.5.h),
          decoration: BoxDecoration(
            color: theme.canvasColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add,
            color: theme.secondaryHeaderColor,
            size: 2.5.h,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 1.2.h,
            ),
            decoration: BoxDecoration(
              color: theme.canvasColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          5 *
                              ((textTheme.labelMedium?.fontSize ?? 14.sp) *
                                  1.4) +
                          8,
                    ),
                    child: Scrollbar(
                      child: TextField(
                        enabled: !isLoading && !isLoadingConversation,
                        controller: _textController,
                        focusNode: _focusNode,
                        cursorColor: theme.hintColor,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        maxLines: 5,
                        minLines: 1,
                        autofocus: true,
                        style: textTheme.labelMedium,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Ask Anything...',
                          hintStyle: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.cardColor,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: showVoiceButton
                      ? GestureDetector(
                          key: const ValueKey('voice'),
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.dividerColor,
                              ),
                              child: Image.asset(
                                'assets/SoundWaves.png',
                                color: theme.scaffoldBackgroundColor,
                                width: 25,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no-voice')),
                ),

                const SizedBox(width: 8),

GestureDetector(
  onTap: isLoadingConversation
      ? null
      : () async {
          if (!canSend) {
            ref.read(chatProvider.notifier).stopGeneration();
            return;
          }

          final text = _textController.text.trim();
          if (text.isEmpty) return;

          _textController.clear();
          setState(() {});
          _focusNode.unfocus();

          await ref
              .read(chatProvider.notifier)
              .sendMessage(text);

          _smoothScrollToLatest();
        },
  child: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: theme.dividerColor,
    ),
    child: AnimatedSwitcher(  // ← moved INSIDE container
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: !canSend
          ? Icon(
              Icons.stop,
              key: const ValueKey('stop'),
              size: 30,
              color: theme.scaffoldBackgroundColor,
            )
          : Image.asset(
              'assets/send.png',
              key: const ValueKey('send'),
              width: 25,
              color: theme.scaffoldBackgroundColor,
            ),
    ),
  ),
),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.2),
        ),
      ],
    ),
  );
}

  Widget _buildMenuBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_outlined, size: 30),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              widget.drawerController.open();
            },
          ),

          const Spacer(),

          if (hasMessages) ...[
            GestureDetector(
              child: Image.asset(
                'assets/new_chat.png',
                color: theme.shadowColor,
                width: 35,
              ),
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                ref.read(chatProvider.notifier).startNewChat();
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
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

  Widget _chatBubble(ChatMessage message, {required ValueKey<String> key}) {
    final isUser = message.role == MessageRole.user;
    final isAssistant = message.role == MessageRole.assistant;
     final isSystem = message.role == MessageRole.system;

    final bool isTypingComplete = message.isTypingComplete;

    if (message.type == MessageType.typing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ScalingTypingDot(),
        ),
      );
    }

      if (message.isError) {
    return _softErrorBubble(message, theme, textTheme);
  }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isUser ? 1.h : 0),
      child: Align(
            alignment:
                isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
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
                  child: isAssistant && !isTypingComplete
                      ? TypingMarkdown(
                          text: message.text,
                          textTheme: textTheme,
                          onCompleted: () {
                            setState(() {
                              message.isTypingComplete = true;
                            });
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

                if (isAssistant || isSystem &&
                    isTypingComplete &&
                    !message.isError) ...[
                  const SizedBox(height: 3),
                  _assistantActionRow(message),
                ],
              ],
            ),
          )
          .animate()
          .fadeIn(duration: 200.ms)
          .slideY(begin: 0.05, duration: 200.ms),
    );
  }

  Widget _assistantActionRow(ChatMessage message) {
     final isLast = messages.first.id == message.id;
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: 0.5,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LikeButton(),
        const SizedBox(width: 16),
        _DislikeButton(),
        const SizedBox(width: 16),
        _CopyIcon(text: message.text),
        const SizedBox(width: 16),
        _actionIcon(Icons.share_outlined),
        // Regenerate only on the last assistant message
        if (isLast && !chatState.isGenerating) ...[
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => ref.read(chatProvider.notifier).regenerateLastResponse(),
            child: Icon(Icons.refresh_rounded, size: 18, color: theme.hintColor),
          ),]
          ],
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon) {
    return Icon(icon, size: 18, color: theme.hintColor);
  }

  

  Widget _connectionHint(String hint, ThemeData theme) {
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

Widget _softErrorBubble(ChatMessage message, ThemeData theme, TextTheme textTheme) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: double.infinity),
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


class _CopyIcon extends StatefulWidget {
  final String text;
  const _CopyIcon({required this.text});

  @override
  State<_CopyIcon> createState() => _CopyIconState();
}

class _CopyIconState extends State<_CopyIcon> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.text));
        setState(() => _copied = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _copied = false);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _copied ? Icons.check_rounded : Icons.copy_outlined,
          key: ValueKey(_copied),
          size: 18,
          color: theme.hintColor,
        ),
      ),
    );
  }
}

class _LikeButton extends StatefulWidget {
  const _LikeButton();
  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _liked = !_liked),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _liked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
          key: ValueKey(_liked),
          size: 18,
          color:  theme.hintColor ,
        ),
      ),
    );
  }
}

class _DislikeButton extends StatefulWidget {
  const _DislikeButton();
  @override
  State<_DislikeButton> createState() => _DislikeButtonState();
}

class _DislikeButtonState extends State<_DislikeButton> {
  bool _disliked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _disliked = !_disliked),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _disliked ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined,
          key: ValueKey(_disliked),
          size: 18,
          color: theme.hintColor 
        ),
      ),
    );
  }
}


