import 'package:drawerbehavior/drawerbehavior.dart';
import 'package:elf_flutter/data/database/chat_database.dart';
import 'package:elf_flutter/provider/chatState.dart';
import 'package:elf_flutter/shared/theme.dart';
import 'package:elf_flutter/provider/shellView.dart';
import 'package:elf_flutter/widgets/ChatScreem/DrawerSearchBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

class ElvesDrawer extends ConsumerWidget {
  /// Pass the controller in so the drawer can close itself before loading.
  final DrawerScaffoldController drawerController;

  const ElvesDrawer({super.key, required this.drawerController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texttheme = Theme.of(context).textTheme;
    final conversationsAsync = ref.watch(conversationsProvider);
    final theme =  Theme.of(context);
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
                drawerController.closeDrawer();
                ref.read(chatProvider.notifier).startNewChat();
              },
              icon: Icons.edit_note_outlined,
            ),
            Leadings(text: 'Images', tap: () {}, icon: Icons.image_outlined),
         
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
                  conversationsAsync.when(
                    data: (conversations) {
                       if (conversations.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 5.h),
                          child: Text(
                            'No conversations yet',
                            style: texttheme.labelSmall?.copyWith(
                              fontSize: 18.sp,
                              color:
                              
                                  theme.secondaryHeaderColor.withOpacity(0.4),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: conversations.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (_, i) {
                          final convo = conversations[i];

                          return ConversationTile(
                            onTap: (){
                              drawerController.closeDrawer();
                              ref
                                  .read(chatProvider.notifier)
                                  .loadConversation(convo.id);
                            },
                            onLongPress: () => _showDeleteDialog(
                              context,
                              ref,
                              convo.id,
                              convo.title,
                            ),
                            drawerController: drawerController,
                             convo: convo, 
                             texttheme: texttheme,
                             
                             );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => const Text("Failed to load chats"),
                  ),
                ],
              ),
            ),

            SizedBox(height: 5.h),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String id,
    String title,
  ) async {
    final theme = Theme.of(context);
    final texttheme = theme.textTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete conversation?',
          style: texttheme.displayMedium,
        ),
        content: Text(
          '"$title" will be permanently deleted.',
          style: texttheme.labelMedium?.copyWith(
            color: theme.secondaryHeaderColor.withOpacity(0.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: texttheme.labelMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: texttheme.labelMedium?.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(chatProvider.notifier).deleteConversation(id);
    }
  }
}

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.drawerController,
    required this.convo,
    required this.texttheme, 
    required this.onTap, 
    required this.onLongPress,
    
  });

  final DrawerScaffoldController drawerController;
  final Conversation convo;
  final TextTheme texttheme;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        splashColor: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.only(
            top: 2.h,
            bottom: 2.h,
            left: 0.5.h,
          ),
          child: Text(
            convo.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: texttheme.bodySmall?.copyWith(color: theme.hintColor, ),
          ),
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
    final theme = Theme.of(context);
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
              SizedBox(width: 5.w),
              Text(text, style: Texttheme.labelMedium?.copyWith(color: theme.hintColor)),
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
          ref.read(shellViewProvider.notifier).state = ShellView.onboarding;
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
                Text('Ghost', style: texttheme.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}