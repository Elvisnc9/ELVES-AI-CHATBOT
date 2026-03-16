import 'package:drawerbehavior/drawerbehavior.dart';
import 'package:elf_flutter/data/database/chat_database.dart';
import 'package:elf_flutter/provider/auth_state.dart';
import 'package:elf_flutter/provider/chatState.dart';
import 'package:elf_flutter/shared/theme.dart';
import 'package:elf_flutter/provider/shellView.dart';
import 'package:elf_flutter/widgets/ChatScreem/DrawerSearchBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

class ElvesDrawer extends ConsumerWidget {
  final DrawerScaffoldController drawerController;
  const ElvesDrawer({super.key, required this.drawerController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texttheme = Theme.of(context).textTheme;
    final conversationsAsync = ref.watch(conversationsProvider);
    final theme = Theme.of(context);

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
                icon: Icons.music_note_outlined),
            Leadings(
                text: 'Code BUD',
                tap: () {},
                icon: Icons.terminal_outlined),

SizedBox(height: 2.h),
            const SearchBox(),

           
SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2.h),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Recent Chat',
              style: texttheme.labelMedium?.copyWith(fontSize: 16.sp,
                              color: theme.hintColor.withOpacity(0.7),),),
            ),
                  conversationsAsync.when(
                    data: (conversations) {
                      if (conversations.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 5.h),
                          child: Text(
                            'No conversations yet',
                            style: texttheme.labelSmall?.copyWith(
                              fontSize: 18.sp,
                              color: theme.secondaryHeaderColor
                                  .withOpacity(0.3),
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
                            onTap: () {
                              drawerController.closeDrawer();
                              ref
                                  .read(chatProvider.notifier)
                                  .loadConversation(convo.id);
                            },
                            onLongPress: () => _showDeleteDialog(
                                context, ref, convo.id, convo.title),
                            drawerController: drawerController,
                            convo: convo,
                            texttheme: texttheme,
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const Text('Failed to load chats'),
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
      BuildContext context, WidgetRef ref, String id, String title) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete conversation?',
            style: theme.textTheme.displayMedium),
        content: Text('"$title" will be permanently deleted.',
            style: theme.textTheme.labelMedium?.copyWith(
                color: theme.secondaryHeaderColor.withOpacity(0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: theme.textTheme.labelMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: Colors.red)),
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
          padding: EdgeInsets.only(top: 2.h, bottom: 2.h, left: 0.5.h),
          child: Text(
            convo.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: texttheme.bodySmall?.copyWith(color: theme.hintColor),
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
    final textTheme = Theme.of(context).textTheme;
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
              Text(text,
                  style: textTheme.labelMedium
                      ?.copyWith(color: theme.hintColor)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DRAWER FOOTER
//  Signed-in → shows real name + avatar → opens settings
//  Guest → shows "Tap to sign in" → opens onboarding
// ─────────────────────────────────────────────

class DrawerFooter extends ConsumerWidget {
  const DrawerFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final texttheme = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);
    final userProfile = authState.userProfile;

    final displayName =
        userProfile?.fullName ?? userProfile?.userName ?? 'Sign In';
    final imageUrl = userProfile?.imageUrl?.toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        enableFeedback: false,
        onTap: () {
          ref.read(shellViewProvider.notifier).state = authState.isAuthenticated
              ? ShellView.settings
              : ShellView.onboarding;
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 1.h),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.dark,
                backgroundImage:
                    (imageUrl != null && imageUrl.isNotEmpty)
                        ? NetworkImage(imageUrl)
                        : null,
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? const Icon(Icons.person_3_outlined, color: Colors.white)
                    : null,
              ),
              SizedBox(width: 3.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(displayName,
                        style: texttheme.labelMedium,
                        overflow: TextOverflow.ellipsis),
                    
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).secondaryHeaderColor.withOpacity(0.4),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}