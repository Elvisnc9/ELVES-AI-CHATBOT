// chat_screen_v2.dart
import 'dart:async';

import 'package:drawerbehavior/drawerbehavior.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

import 'package:elf_flutter/widgets/elvesDrawer.dart';
import 'package:elf_flutter/state/chatState.dart';
import 'package:elf_flutter/state/shellView.dart';
import 'package:elf_flutter/widgets/ChatScreem/typingdot_indicator.dart';
import 'package:elf_flutter/widgets/ChatScreem/chatModels.dart';

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

  // Track previous message count to detect first message
  int _prevMessageCount = 0;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInBack,
        );
      }
    });
  }

  TextTheme get textTheme => Theme.of(context).textTheme;
   ChatState get chatState => ref.watch(chatProvider);
  List<ChatMessage> get messages => chatState.messages;
 bool get hasMessages => messages.isNotEmpty;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Detect first message arrival (not typing)
    if (messages.length != _prevMessageCount) {
      _prevMessageCount = messages.length;
      if (hasMessages) _scrollToBottom();
    }

    return SizedBox.expand(
      child: Stack(
        children: [
          // ── LAYER 1: Chat List ──────────────────────────────────
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: hasMessages ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              child: IgnorePointer(
                ignoring: !hasMessages,
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
                      stops: [0.0, 0.3, 0.8, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.only(
                      top: 70,
                      bottom: 10.h,
                      left: 12,
                      right: 12,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _chatBubble(message, key:ValueKey(message.id)
                      
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // ── LAYER 2: Welcome Content ────────────────────────────
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: hasMessages ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
              child: IgnorePointer(
                ignoring: hasMessages,
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
            child: _buildInputBar(theme, chatState.isLoading,  )),

          // ── LAYER 4: Loading dots ───────────────────────────────
          if (chatState.isLoading)
            Positioned(
              bottom: 10.h,
              left: 20,
              child: BouncingTypingDots(),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeContent(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // push up slightly from true center
        SizedBox(
          height: 25.h,
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'How May I help you \ntoday,  Victor?',
            style: textTheme.displayLarge?.copyWith(
              fontSize: 32.sp,
            ),
          ),
        ).animate().fadeIn().slideX(begin: 0.3),
        
        PremiumFloatingChips(),
        
        // space for chips + input below
      ],
    );
  }

  

  Widget _buildInputBar(ThemeData theme, bool isLoading,
  ) {
final messages = ref.watch(chatProvider).messages;

final bool isTypingComplete = messages.isEmpty
    ? true
    : messages.last.isTypingComplete;
    final bool canSend = !isLoading && isTypingComplete;

    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
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
            SizedBox(width: 1.w),
            Expanded(
              
              child: AnimatedSize(
                
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.h,
                    vertical: 1.2.h,
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
                        onTap: isLoading  
                            ? null
                            : () async {
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
                            color: theme.dividerColor,
                          ),
                          child: Icon(
                            isLoading ? Icons.square_outlined : Icons.send_outlined,
                            size: 18,
                            color: theme.scaffoldBackgroundColor,
                          ),
                        ).animate().scale(duration: 150.ms).fadeIn(),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuBar(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_outlined, size:30),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              widget.drawerController
                  .openDrawer(); // use controller from parent
            },
          ),
          // GestureDetector(
          //   onTap: () =>
          //       ref.read(shellViewProvider.notifier).state = ShellView.onboarding,
          //   child: Container(
          //     padding: const EdgeInsets.all(6),
          //     decoration: BoxDecoration(
          //       color: theme.scaffoldBackgroundColor.withOpacity(0.4),
          //       borderRadius: BorderRadius.circular(20),
          //     ),
          //     child: Row(
          //       children: [
          //         const Icon(Icons.star, color: Colors.yellow, size: 20),
          //         const SizedBox(width: 4),
          //         Text(
          //           'Upgrade',
          //           style: theme.textTheme.bodyMedium?.copyWith(
          //             color: Colors.white,
          //           ),
          //         ),
                

                  
          //       ],
          //     ),
          //   ),
          // ),


            Spacer(),


            if(hasMessages)...[IconButton(
            
            icon: const Icon(Icons.edit_note_outlined,),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              ref.read(chatProvider.notifier).clearChat();
                _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
              
             // use controller from parent
            },
          ),],
                   

           IconButton(
            icon: const Icon(Icons.settings_outlined,),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
               ref.read(shellViewProvider.notifier).state = ShellView.settings;
             // use controller from parent
            },
          ),

        ]
      ),
    );
  }

  Widget _chatBubble(ChatMessage message, {required ValueKey<String> key}) {
    final theme = Theme.of(context);
    final isUser = message.role == MessageRole.user;
    final isAssistant = message.role == MessageRole.assistant;
    final bool istypingComplete = message.isTypingComplete;

    return Padding(
      padding: EdgeInsets.symmetric(vertical:  isUser? 1.h : 0),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            /// 💬 BUBBLE
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(maxWidth: isUser ? 75.w : 100.w),
              decoration: BoxDecoration(
                color: isUser ? theme.canvasColor : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child:isAssistant && !istypingComplete ?
        TypingMarkdown(
      text: message.text,
      textTheme: textTheme,
      onCompleted: () {
        setState((){
          message.isTypingComplete = true;
        });
       
      },
        )
      :
        MarkdownBody(
      data: message.text,
      styleSheet: MarkdownStyleSheet(
        p: textTheme.displayMedium,
        strong: textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
        )
      
            ),
        //  color: isUser ? theme.hintColor : theme.shadowColor,
        //               fontSize: 15.sp,
            /// ⚡ ACTION ROW (Assistant Only)
            if (isAssistant && istypingComplete) ...[
              const SizedBox(height: 3),
              _assistantActionRow(message),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, duration: 200.ms),
    );
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
            opacity: 0.5,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionIcon(Icons.thumb_up_alt_outlined),
                SizedBox(width: 16),
                _actionIcon(Icons.thumb_down_alt_outlined),
                SizedBox(width: 16),
                _actionIcon(Icons.copy_outlined),
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
      color: theme.hintColor,
    );
  }
}

// AnimatedOpacity(
//   opacity: hasMessages ? 0.0 : 1.0,
//   duration: const Duration(milliseconds: 250),
//   child: IgnorePointer(
//     ignoring: hasMessages,
//     child: _buildSuggestionChips(theme),
//   ),
// ),

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
          color: theme.canvasColor,
          percentage: 0.85,
          degree: 15,
          drawerWidth: 300,
          slide: true,
          animation: true,
          alignment: Alignment.topLeft,
          
          footerView: DrawerFooter(),
          child: ElvesDrawer(),
        ),
      ],
      builder: (context, id) {
        return ChatView(drawerController: drawerController);
      },
    );
  }
}




    // Widget MenuBar(BuildContext context, WidgetRef ref) {
    //   return  Padding(
    //     padding:  EdgeInsets.only(top: 5.h),
    //     child: Row(
    //                       children: [
    //                         /// ☰ MENU (OPENS DRAWER)
    //                         IconButton(
    //                           onPressed: () {
    //                             FocusManager.instance.primaryFocus?.unfocus();
    //                             drawerController.openDrawer();
    //                           },
    //                           icon: const Icon(Icons.menu),
    //                         ),
    //                         SizedBox(width: 5.w),
    //                         Material(
    //                           type: MaterialType.transparency,
    //                           child: GestureDetector(
    //                             onTap: () {
    //                               FocusManager.instance.primaryFocus?.unfocus();
    //                               ref.read(shellViewProvider.notifier).state =
    //                                   ShellView.home;
    //                             },
    //                             child: Container(
    //                               padding: EdgeInsets.all(1.h),
    //                               decoration: BoxDecoration(
    //                                 color:
    //                                     theme.scaffoldBackgroundColor.withOpacity(0.4),
    //                                 borderRadius: BorderRadius.circular(20),
    //                               ),
    //                               child: Row(
    //                                 children: [
    //                                   Icon(
    //                                     Icons.star,
    //                                     color: Colors.yellow,
    //                                     size: 2.h,
    //                                   ),
    //                                   SizedBox(width: 1.w),
    //                                   Text(
    //                                     'Upgrade',
    //                                     style: textTheme.displayLarge?.copyWith(
    //                                       fontWeight: FontWeight.bold,
    //                                       fontSize: 12.sp,
    //                                     ),
    //                                   ),
    //                                 ],
    //                               ),
    //                             ),
    //                           ),
    //                         ),
    //                       ],
    //                     ),
    //   );
    // }
  




class TypingMarkdown extends StatefulWidget {
  final String text;
  final Duration speed;
  final TextTheme textTheme;
  final VoidCallback? onCompleted;
  const TypingMarkdown({
    super.key,
    required this.text,
    required this.textTheme,
     this.onCompleted,
    this.speed = const Duration(milliseconds: 5),
  });

  @override
  State<TypingMarkdown> createState() => _TypingMarkdownState();
}

class _TypingMarkdownState extends State<TypingMarkdown> {
  String _displayText = '';
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        timer.cancel();
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _displayText,
      styleSheet: MarkdownStyleSheet(
        p: widget.textTheme.displayMedium,
        strong: widget.textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
