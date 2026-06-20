import 'package:elf_flutter/provider/chatState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

class InputBar extends ConsumerStatefulWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback onScrollToLatest;

  const InputBar({super.key, 
    required this.textController,
    required this.focusNode,
    required this.onScrollToLatest,
  });

  @override
  ConsumerState<InputBar> createState() => InputBarState();
}

class InputBarState extends ConsumerState<InputBar> {
  // Local notifier — only the send button listens to this, not the whole tree
  late final ValueNotifier<bool> _hasText;

  @override
  void initState() {
    super.initState();
    _hasText = ValueNotifier(false);
    widget.textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final next = widget.textController.text.trim().isNotEmpty;
    if (_hasText.value != next) _hasText.value = next;
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    _hasText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = Theme.of(context).textTheme;

    // Only watch the two booleans this widget actually needs
    final isGenerating = ref.watch(chatProvider.select((s) => s.isGenerating));
    final isLoadingConversation = ref.watch(
      chatProvider.select((s) => s.isLoadingConversation),
    );
    final isLoading = ref.watch(chatProvider.select((s) => s.isLoading));

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 1.2.h),
        decoration: BoxDecoration(
          color: theme.canvasColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Text field ──────────────────────────────────────────
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      5 * ((textTheme.labelMedium?.fontSize ?? 14.sp) * 1.4) +
                          8,
                ),
                child: Scrollbar(
                  child: TextField(
                    enabled: !isLoading && !isLoadingConversation,
                    controller: widget.textController,
                    focusNode: widget.focusNode,
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

            const SizedBox(width: 8),

            // ── Send / Stop button — ValueListenableBuilder so only
            //    this icon rebuilds when text changes ────────────────
            ValueListenableBuilder<bool>(
              valueListenable: _hasText,
              builder: (context, hasText, _) {
                return GestureDetector(
                  onTap: isLoadingConversation
                      ? null
                      : () async {
                          if (!isGenerating == false) {
                            // i.e. isGenerating == true → stop
                            ref.read(chatProvider.notifier).stopGeneration();
                            return;
                          }
                          final text = widget.textController.text.trim();
                          if (text.isEmpty) return;
                          widget.textController.clear();
                          widget.focusNode.unfocus();
                          await ref
                              .read(chatProvider.notifier)
                              .sendMessage(text);
                          widget.onScrollToLatest();
                        },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.dividerColor,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: isGenerating
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
                );
              },
            ),
          ],
        ),
      )
    );
  }
}
