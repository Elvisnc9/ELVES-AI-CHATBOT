import 'package:elf_flutter/provider/chatState.dart';
import 'package:elf_flutter/shared/theme.dart';
import 'package:elf_flutter/provider/shellView.dart';
import 'package:elf_flutter/widgets/ChatScreem/DrawerSearchBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

class ElvesDrawer extends ConsumerWidget {
  const ElvesDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texttheme = Theme.of(context).textTheme;
    final chatNotifier = ref.read(chatProvider.notifier);
    final conversationsAsync = ref.watch(conversationsProvider);

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Leadings(
              text: 'New Chat',
              tap: () {
                ref.read(chatProvider.notifier).startNewChat();
              },
              icon: Icons.edit_note_outlined,
            ),
            Leadings(text: 'Images', tap: () {}, icon: Icons.image_outlined),
            Leadings(
              text: 'Video Prompt',
              tap: () {},
              icon: Icons.video_camera_back_outlined,
            ),
            Leadings(
              text: 'AI music',
              tap: () {},
              icon: Icons.music_note_outlined,
            ),
            Leadings(
              text: 'Code BUD',
              tap: () {},
              icon: Icons.terminal_outlined,
            ),

            SearchBox(),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.h),
              child: Column(
                children: [
                  SizedBox(height: 3.h),
                  SizedBox(
                    child: conversationsAsync.when(
                      data: (conversations) {
                        return ListView.builder(
                          itemCount: conversations.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (_, i) {
                            final convo = conversations[i];

                            return Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                splashColor: Colors.white10,
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  ref
                                      .read(chatProvider.notifier)
                                      .loadConversation(convo.id);
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: 2.h,
                                    bottom: 2.h,
                                    left: 0.5.h,
                                  ),
                                  child: Text(
                                    convo.title,
                                    maxLines: 1,
                                    style: texttheme.labelMedium,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },

                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),

                      error: (e, _) => const Text("Failed to load chats"),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 5.h,
            ),
          ],
        ),
      ),
    );
  }
}

class Leadings extends StatelessWidget {
  const Leadings({
    super.key,
    required this.text,
    required this.tap,
    required this.icon,
  });

  final String text;
  final VoidCallback tap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Texttheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white10,
        onTap: tap,
        child: Padding(
          padding: EdgeInsets.only(top: 1.5.h, bottom: 1.5.h, left: 1.h),
          child: Row(
            children: [
              Icon(icon),

              SizedBox(
                width: 5.w,
              ),
              Text(
                text,
                style: Texttheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerFooter extends ConsumerWidget {
  const DrawerFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texttheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        enableFeedback: false,
        onTap: () {
          ref.read(shellViewProvider.notifier).state = ShellView.settings;
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 1.h),
          child: Container(
            color: Colors.transparent,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.dark,
                  child: Icon(Icons.person_3_outlined),
                ),

                SizedBox(width: 3.h),

                Text('Ngwu Elvis', style: texttheme.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
