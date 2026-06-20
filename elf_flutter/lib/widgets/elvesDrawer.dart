// elvesDrawer.dart
//
// Removed:
//   • ElvesDrawerController (ChangeNotifier)
//   • ElvesDrawerOverlay (AnimationController, scrim, Transform.translate)
//
// Kept intact:
//   • All content widgets: _DrawerPanel, _SearchBar, _ConversationGroup,
//     _ConvoTile, _DrawerFooter, _LeadingItem
//   • ElvesDrawerPage — the new full-screen page that sits in the PageView

import 'package:elf_flutter/data/database/chat_database.dart';
import 'package:elf_flutter/provider/auth_state.dart';
import 'package:elf_flutter/provider/chatState.dart';
import 'package:elf_flutter/shared/theme.dart';
import 'package:elf_flutter/provider/shellView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ELVES DRAWER PAGE
//  Full-screen page living at index 0 in the AppShell PageView.
//  Drag-left → peek chat → snap to page 1.
// ─────────────────────────────────────────────────────────────────────────────

class ElvesDrawerPage extends ConsumerStatefulWidget {
  final PageController pageController;
  final VoidCallback onClose;

  const ElvesDrawerPage({
    super.key,
    required this.pageController,
    required this.onClose,
  });

  @override
  ConsumerState<ElvesDrawerPage> createState() => _ElvesDrawerPageState();
}

class _ElvesDrawerPageState extends ConsumerState<ElvesDrawerPage> {
  // Track the drag start offset so we can compute delta from page-0 edge.
  double _dragStartX = 0;
  // Page offset at the moment the drag began (should always be ~0.0 on this page).
  double _pageOffsetAtDragStart = 0;

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _pageOffsetAtDragStart = widget.pageController.page ?? 0.0;
    ref.read(inputAutofocusProvider.notifier).state = false;
      FocusManager.instance.primaryFocus?.unfocus(); 
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx - _dragStartX;
ref.read(inputAutofocusProvider.notifier).state = false;
    // Left drag (negative dx) moves toward page 1
    final newOffset = _pageOffsetAtDragStart - (dx / screenWidth);
    final clamped = newOffset.clamp(0.0, 1.0);
    widget.pageController.jumpTo(clamped * screenWidth);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final currentPage = widget.pageController.page ?? 0.0;
    ref.read(inputAutofocusProvider.notifier).state = false;
    // Progress toward page 1 (0 = fully on drawer, 1 = fully on chat)
    final progress = currentPage; // page offset in [0,1]

    // Snap to chat if dragged far enough left or flicked left
    if (velocity < -300 || progress > 0.4) {
      widget.onClose(); // animateToPage(1)
    } else {
      widget.pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      
      child: _DrawerPanel(onClose: widget.onClose),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DRAWER PANEL  (unchanged content — just extracted from the old overlay)
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerPanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const _DrawerPanel({required this.onClose});

  @override
  ConsumerState<_DrawerPanel> createState() => _DrawerPanelState();
}

class _DrawerPanelState extends ConsumerState<_DrawerPanel> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearching = false;


  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && !_isSearchExpanded) {
        setState(() => _isSearchExpanded = true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final conversationsAsync = ref.watch(conversationsProvider);
    final autofocus = ref.watch(inputAutofocusProvider);

    // Filter conversations by search query
    final filtered = conversationsAsync.whenData(
      (list) => _searchQuery.isEmpty
          ? list
          : list
                .where(
                  (c) => c.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList(),
    );

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 2.h,
            vertical: 2.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            
             AnimatedContainer(
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  height: 6.h,
  decoration: BoxDecoration(
    color: _isSearching ? theme.canvasColor : Colors.transparent,
    borderRadius: BorderRadius.circular(30),
  ),
  child: _isSearching
      // ── SEARCH MODE ──────────────────────────────────────
      ? Row(
          children: [
            SizedBox(width: 1.5.h),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (q) => setState(() => _searchQuery = q),
                autofocus: true,
                cursorColor: theme.hintColor,
                style: textTheme.labelMedium,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: textTheme.labelMedium?.copyWith(
                    color: theme.hintColor.withOpacity(0.8),
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
                
                _searchFocusNode.unfocus();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 1.5.h),
                child: Icon(Icons.cancel_sharp,
                size: 30,
                )
              ),
            ),
          ],
        )
      // ── NORMAL MODE ──────────────────────────────────────
      : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Elves AI',
              style: textTheme.bodyLarge?.copyWith(fontSize: 35.sp),
            ),
            Container(
              width: 30.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: theme.canvasColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _isSearching = true);
                        // slight delay so the animation starts before focus
                        Future.delayed(
                          const Duration(milliseconds: 150),
                          () => _searchFocusNode.requestFocus(),
                        );
                      },
                      child: Icon(Icons.search, color: theme.hintColor, size: 35),
                    ),
                    GestureDetector(
                      onTap: () {
                        widget.onClose();
                        ref.read(chatProvider.notifier).startNewChat();
                      },
                      child: Image.asset('assets/chat.png',  height: 30, 
                      color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
),

              SizedBox(height: 3.h),

              Text(
                'Coversation  History',
                textAlign: TextAlign.center,
                style: textTheme.displayLarge?.copyWith(fontSize: 20.sp, ),
              ),

              // ── Conversations list ────────────────────────────────────────
              Expanded(
                child: filtered.when(
                  data: (conversations) {
                    if (conversations.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 5.h),
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No conversations yet'
                                : 'No results for "$_searchQuery"',
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 15.sp,
                              color: theme.secondaryHeaderColor.withOpacity(
                                0.3,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final groups = _groupConversations(conversations);

                    return ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (_, i) {
                        final group = groups[i];
                        return _ConversationGroup(
                          label: group.label,
                          conversations: group.items,
                          onTap: (convo) {
                            widget.onClose();
                            ref
                                .read(chatProvider.notifier)
                                .loadConversation(convo.id);
                          },
                          onDelete: (convo) => _showDeleteDialog(
                            context,
                            ref,
                            convo.id,
                            convo.title,
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load',
                      style: textTheme.labelSmall,
                    ),
                  ),
                ),
              ),

              // ── Footer ───────────────────────────────────────────────────
              const Divider(height: 1, thickness: 0.3),
              _DrawerFooter(onClose: widget.onClose),
            ],
          ),
        ),
      ),
    );
  }

  List<_ConvoGroup> _groupConversations(List<Conversation> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final last7 = today.subtract(const Duration(days: 7));
    final last30 = today.subtract(const Duration(days: 30));

    final Map<String, List<Conversation>> buckets = {
      'Today': [],
      'Yesterday': [],
      'Previous 7 Days': [],
      'Previous 30 Days': [],
      'Older': [],
    };

    for (final c in list) {
      final d = DateTime(
        c.lastActiveAt.year,
        c.lastActiveAt.month,
        c.lastActiveAt.day,
      );
      if (!d.isBefore(today)) {
        buckets['Today']!.add(c);
      } else if (!d.isBefore(yesterday)) {
        buckets['Yesterday']!.add(c);
      } else if (d.isAfter(last7)) {
        buckets['Previous 7 Days']!.add(c);
      } else if (d.isAfter(last30)) {
        buckets['Previous 30 Days']!.add(c);
      } else {
        buckets['Older']!.add(c);
      }
    }

    return buckets.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => _ConvoGroup(label: e.key, items: e.value))
        .toList();
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String id,
    String title,
  ) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete conversation?',
          style: theme.textTheme.displayMedium,
        ),
        content: Text(
          '"$title" will be permanently deleted.',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.secondaryHeaderColor.withOpacity(0.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: theme.textTheme.labelMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(chatProvider.notifier).deleteConversation(id);
    }
  }
}


// ─────────────────────────────────────────────
//  CONVERSATION GROUP  (unchanged)
// ─────────────────────────────────────────────

class _ConvoGroup {
  final String label;
  final List<Conversation> items;
  const _ConvoGroup({required this.label, required this.items});
}

class _ConversationGroup extends StatelessWidget {
  final String label;
  final List<Conversation> conversations;
  final ValueChanged<Conversation> onTap;
  final ValueChanged<Conversation> onDelete;

  const _ConversationGroup({
    required this.label,
    required this.conversations,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 1.5.h, bottom: 0.5.h),
          child: Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 12.sp,
              color: theme.hintColor.withOpacity(0.45),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ...conversations.map(
          (c) => _ConvoTile(
            convo: c,
            onTap: () => onTap(c),
            onDelete: () => onDelete(c),
          ),
        ),
      ],
    );
  }
}

class _ConvoTile extends StatefulWidget {
  final Conversation convo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConvoTile({
    required this.convo,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_ConvoTile> createState() => _ConvoTileState();
}

class _ConvoTileState extends State<_ConvoTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onDelete,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: EdgeInsets.symmetric(horizontal: 1.h, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: _hovering
                ? theme.hintColor.withOpacity(0.07)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.convo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    fontSize: 16.sp,
                    color: theme.hintColor.withOpacity(0.85),
                  ),
                ),
              ),
              if (_hovering)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: theme.hintColor.withOpacity(0.5),
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

// ─────────────────────────────────────────────
//  DRAWER FOOTER  (unchanged)
// ─────────────────────────────────────────────

class _DrawerFooter extends ConsumerWidget {
  final VoidCallback onClose;
  const _DrawerFooter({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final authState = ref.watch(authProvider);
    final userProfile = authState.userProfile;

    final displayName =
        userProfile?.fullName ?? userProfile?.userName ?? 'Sign in';
    final imageUrl = userProfile?.imageUrl?.toString();

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 1.h, vertical: 1.5.h),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.hintColor,
              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                  ? NetworkImage(imageUrl)
                  : null,
              child: (imageUrl == null || imageUrl.isEmpty)
                  ?  Icon(
                      Icons.person_3_outlined,
                      color: theme.canvasColor,
                      size: 25,
                    )
                  : null,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                displayName,
                style: textTheme.labelMedium?.copyWith(fontSize: 18.sp),
                overflow: TextOverflow.ellipsis,
              ),
            ),
           
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  LEADING ITEM  (unchanged)
// ─────────────────────────────────────────────

class _LeadingItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _LeadingItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        splashColor: theme.hintColor.withOpacity(0.08),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 1.2.h),
          child: Row(
            children: [
              Icon(icon, color: theme.hintColor, size: 20),
              SizedBox(width: 4.w),
              Text(
                text,
                style: textTheme.labelMedium?.copyWith(
                  color: theme.hintColor.withOpacity(0.85),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BACKWARD COMPAT SHIMS
//  Keep these until you've cleaned up old imports.
// ─────────────────────────────────────────────

/// Legacy stub — safe to delete once no other file imports it.
class ElvesDrawerController extends ChangeNotifier {
  void open() {}
  void close() {}
  void toggle() {}
}

/// Legacy stub — safe to delete once no other file imports it.
class ElvesDrawerOverlay extends StatelessWidget {
  final ElvesDrawerController controller;
  const ElvesDrawerOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Legacy stub — safe to delete once no other file imports it.
class ElvesDrawer extends ConsumerWidget {
  final ElvesDrawerController drawerController;
  const ElvesDrawer({super.key, required this.drawerController});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}

/// Legacy stub — safe to delete once no other file imports it.
class DrawerFooter extends ConsumerWidget {
  const DrawerFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
