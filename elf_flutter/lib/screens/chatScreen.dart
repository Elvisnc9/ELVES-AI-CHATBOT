import 'package:drawerbehavior/drawerbehavior.dart';
import 'package:elf_flutter/screens/elvesDrawer.dart';
import 'package:elf_flutter/state/chatState.dart';
import 'package:elf_flutter/state/shellView.dart';
import 'package:elf_flutter/widgets/ChatScreem/DrawerSearchBar.dart';
import 'package:elf_flutter/widgets/ChatScreem/typingdot_indicator.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  late final DrawerScaffoldController drawerController;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    drawerController = DrawerScaffoldController();
  }

  /// Scroll to newest message
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // reverse: true → top = newest
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  TextTheme get textTheme => Theme.of(context).textTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
     final chatState = ref.watch(chatProvider);
     final messages = chatState.messages;
   
    return SafeArea(
      child: DrawerScaffold(
        controller: drawerController,
        drawers: [
          SideDrawer(
            color: theme.canvasColor,
            percentage: 0.85,
            degree: 15,
            drawerWidth: 250,
            slide: true,
            animation: true,
            alignment: Alignment.topLeft,
            headerView: SearchBox(),
            footerView: DrawerFooter(),
            child: ElvesDrawer(),
          ),
        ],
        builder: (context, id) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
              drawerController.closeDrawer();
            },
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          /// ☰ MENU (OPENS DRAWER)
                          IconButton(
                            onPressed: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              drawerController.openDrawer();
                            },
                            icon: const Icon(Icons.menu),
                          ),
                          SizedBox(width: 5.w),
                          Material(
                            type: MaterialType.transparency,
                            child: GestureDetector(
                              onTap: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                ref.read(shellViewProvider.notifier).state =
                                    ShellView.home;
                              },
                              child: Container(
                                padding: EdgeInsets.all(1.h),
                                decoration: BoxDecoration(
                                  color:
                                      theme.scaffoldBackgroundColor.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.yellow,
                                      size: 2.h,
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      'Upgrade',
                                      style: textTheme.displayLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
      
                  /// Chat List
                  Positioned.fill(
                    top: 60,
                    child: Consumer(
                      builder: (context, ref, _) {
                       
                        final isLoading = chatState.isLoading;
      
                        // Auto-scroll whenever messages change
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });
      
                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: EdgeInsets.only(
                            top: 80,
                            bottom: MediaQuery.of(context).viewInsets.bottom + 90,
                            left: 12,
                            right: 12,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return _chatBubble(message);
                          },
                        );
                      },
                    ),
                  ),
      
                  /// Loading indicator
                  Consumer(
                    builder: (context, ref, _) {
                      final isLoading = ref.watch(chatProvider).isLoading;
                      if (!isLoading) return const SizedBox.shrink();
                      return Positioned(
                        bottom: 80,
                        left: 20,
                        child: BouncingTypingDots(),
                        );
                    },
                  ),
      
                  /// Input field + send button
                   
               
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.h),
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
                        SizedBox(width: 1.w),
                        Expanded(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.h,
                                vertical: 1.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: theme.canvasColor,
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  /// TEXT INPUT
                                  Expanded(
                                    child: TextField(
                                      controller: _textController,
                                      focusNode: _focusNode,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: TextInputAction.newline,
                                      maxLines: null,
                                      minLines: 1,
                                      style: textTheme.labelMedium,
                                      decoration: InputDecoration(
                                        hintText: 'Ask Elves Anything...',
                                        hintStyle: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          color: theme.cardColor,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                        
                                  SizedBox(width: 2.w),
                        
                                  /// SEND BUTTON
                                  GestureDetector(
                                    onTap: () async {
                                      final text = _textController.text.trim();
                                      if (text.isEmpty) return;
                        
                                      _textController.clear();
                                      _focusNode.requestFocus();
                        
                                      await ref
                                          .read(chatProvider.notifier)
                                          .sendMessage(text);
                        
                                      _scrollToBottom();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme.cardColor,
                                      ),
                                      child: Icon(
                                        Icons.send,
                                        size: 18,
                                        color: theme.scaffoldBackgroundColor,
                                      ),
                                    )
                                        .animate()
                                        .scale(duration: 150.ms)
                                        .fadeIn(),
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 250.ms)
                                .slideY(begin: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Chat bubble
Widget _chatBubble(ChatMessage message) {
  final theme = Theme.of(context);
  final isUser = message.role == MessageRole.user;
  final isAssistant = message.role == MessageRole.assistant;

  return Align(
    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        /// 💬 BUBBLE
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          constraints:
              BoxConstraints(maxWidth: isUser ? 75.w : 100.w),
          decoration: BoxDecoration(
            color: isUser ? theme.canvasColor : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            message.text,
            style: textTheme.displayMedium?.copyWith(
              color: isUser
                  ? theme.hintColor
                  : theme.shadowColor,
              fontSize: 16.sp,
            ),
          ),
        ),

        /// ⚡ ACTION ROW (Assistant Only)
        if (isAssistant) ...[
          const SizedBox(height: 4),
          _assistantActionRow(message),
        ],
        
      ],
    ),
  )
      .animate()
      .fadeIn(duration: 200.ms)
      .slideY(begin: 0.05, duration: 200.ms);
}


Widget _assistantActionRow(ChatMessage message) {
  final theme = Theme.of(context);

  return Padding(
    padding: const EdgeInsets.only(left: 14), // aligns with bubble padding
    child: StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
    
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity:  0.5,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionIcon(Icons.thumb_up_alt_outlined),
              SizedBox(width: 16),
              _actionIcon(Icons.thumb_down_alt_outlined),
              SizedBox(width: 16),
              _actionIcon(Icons.copy_outlined),
              SizedBox(width: 16),
              _actionIcon(Icons.refresh),
              SizedBox(width: 16),
              _actionIcon(Icons.share_outlined),
            ],
          ),
        );
      },
    ),
  );
}



Widget _actionIcon(IconData icon) {
  final theme = Theme.of(context);

  return Icon(
    icon,
    size: 18,
    color: theme.hintColor.withOpacity(0.8),
  );
}


}

class HeroButton extends StatelessWidget {
  const HeroButton({super.key, required this.onPressed, required this.child});
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(1.h),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: child,
      ),
    );
  }
}





class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
     this.ischatScreen = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Future<void> Function(String text) onSend;
 final bool ischatScreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Row(
      children: [
        /// PLUS BUTTON
        if (ischatScreen) ...[
          Container(
            padding: EdgeInsets.all(2.h),
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
          SizedBox(width: 1.w),
        ],
      

        /// INPUT CONTAINER
        Expanded(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 2.h,
                vertical: 1.5.h,
              ),
              decoration: BoxDecoration(
                color: theme.canvasColor,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  /// TEXT FIELD
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      maxLines: null,
                      minLines: 1,
                      style: textTheme.labelMedium,
                      decoration: InputDecoration(
                        hintText: 'Ask Elves Anything...',
                        hintStyle: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.cardColor.withOpacity(0.4),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),

                  SizedBox(width: 2.w),

                  /// SEND BUTTON
                  GestureDetector(
                    onTap: () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;

                      controller.clear();
                      focusNode.requestFocus();

                      await onSend(text);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.cardColor,
                      ),
                      child: Icon(
                        Icons.send,
                        size: 18,
                        color: theme.scaffoldBackgroundColor,
                      ),
                    )
                        .animate()
                        .scale(duration: 150.ms)
                        .fadeIn(),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 250.ms)
                .slideY(begin: 0.2),
          ),
        ),
      ],
    );
  }
}
