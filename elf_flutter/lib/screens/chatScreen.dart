import 'package:drawerbehavior/drawerbehavior.dart';
import 'package:elf_flutter/widgets/ChatScreem/chatShimmer.dart';
import 'package:elf_flutter/widgets/ChatScreem/typingMarkdownanimation.dart';
import 'package:flutter/material.dart';
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
  late final DrawerScaffoldController drawerController;

  @override
  void initState() {
    super.initState();
    drawerController = DrawerScaffoldController();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DrawerScaffold(
      controller: drawerController,
      drawers: [
        SideDrawer(
          color: theme.scaffoldBackgroundColor,
          percentage: 0.85,
          degree: 15,
          drawerWidth: 300,
          slide: true,
          alignment: Alignment.topLeft,
          footerView: DrawerFooter(),
          child: ElvesDrawer(drawerController: drawerController),
        ),
      ],
      builder: (context, id) {
        return ChatView(drawerController: drawerController);
      },
    );
  }
}


class ChatView extends ConsumerStatefulWidget {
  final DrawerScaffoldController drawerController;
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    });
  }

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
    if (messages.length != _prevMessageCount) {
      _prevMessageCount = messages.length;
      if (hasMessages) _scrollToBottom();
    }

    final isLoadingConversation = chatState.isLoadingConversation;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,

        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox.expand(
          child: Stack(
            children: [
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
                                    itemCount: messages.length,
                                    itemBuilder: (context, index) {
                                      final message = messages[index];
                                      return _chatBubble(
                                        message,
                                        key: ValueKey(message.id),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

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

              Positioned(
                top: 3.h,
                left: 0,
                right: 0,
                child: _buildMenuBar(theme),
              ),

              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: _buildInputBar(theme, chatState.isLoading),
              ),
            ],
          ),
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
    final bool canSend = !isGenerating && !isTyping;

    final bool showVoiceButton =
        ref.watch(chatProvider.notifier).activeConversationId == null &&
        !isLoading;

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
                            onTap: () {
                              ref.read(shellViewProvider.notifier).state =
                                  ShellView.voicechat;
                            },
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

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: GestureDetector(
                      key: ValueKey(!canSend),
                      onTap: isLoadingConversation
                          ? null
                          : () async {
                              if (!canSend) {
                                ref
                                    .read(chatProvider.notifier)
                                    .stopGeneration();
                                return;
                              }

                              final text = _textController.text.trim();
                              if (text.isEmpty) return;

                              _textController.clear();
                              _focusNode.unfocus();

                              await ref
                                  .read(chatProvider.notifier)
                                  .sendMessage(text);

                              _scrollToBottom();
                            },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.dividerColor,
                        ),
                        child: !canSend
                            ? Icon(
                                Icons.stop,

                                size: 30,
                                color: theme.scaffoldBackgroundColor,
                              )
                            : Image.asset(
                                'assets/send.png',
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
              widget.drawerController.openDrawer();
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
    final bool isTypingComplete = message.isTypingComplete;

    if (message.type == MessageType.typing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: BouncingTypingDots(),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isUser ? 1.h : 0),
      child:
          Align(
                alignment: isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
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

                    if (isAssistant &&
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
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: 0.5,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionIcon(Icons.thumb_up_alt_outlined),
            const SizedBox(width: 16),
            _actionIcon(Icons.thumb_down_alt_outlined),
            const SizedBox(width: 16),
            _actionIcon(Icons.copy_outlined),
            const SizedBox(width: 16),
            _actionIcon(Icons.share_outlined),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon) {
    return Icon(icon, size: 18, color: theme.hintColor);
  }
}

