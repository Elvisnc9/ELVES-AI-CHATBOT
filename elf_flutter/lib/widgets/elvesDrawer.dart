import 'package:elf_flutter/data/database/chat_database.dart';
import 'package:elf_flutter/provider/auth_state.dart';
import 'package:elf_flutter/provider/chatState.dart';
import 'package:elf_flutter/shared/theme.dart';
import 'package:elf_flutter/provider/shellView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

// ─────────────────────────────────────────────
//  DRAWER CONTROLLER
//  A simple ValueNotifier so ChatScreen can open/close
//  the drawer without depending on drawerbehavior.
// ─────────────────────────────────────────────

class ElvesDrawerController extends ChangeNotifier {
  bool _isOpen = false;
  bool get isOpen => _isOpen;

  void open() {
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    _isOpen = false;
    notifyListeners();
  }

  void toggle() {
    _isOpen = !_isOpen;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────
//  ELVES DRAWER OVERLAY
//  Drop this anywhere in a Stack (above the chat body).
//  It renders its own scrim + slide-in panel.
// ─────────────────────────────────────────────

class ElvesDrawerOverlay extends ConsumerStatefulWidget {
  final ElvesDrawerController controller;

  const ElvesDrawerOverlay({super.key, required this.controller});

  @override
  ConsumerState<ElvesDrawerOverlay> createState() => _ElvesDrawerOverlayState();
}

class _ElvesDrawerOverlayState extends ConsumerState<ElvesDrawerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  late Animation<double> _scrimAnim;

  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  // Drawer width when NOT in search mode
  double get _drawerWidth => MediaQuery.of(context).size.width * 0.80;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _slideAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _scrimAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    widget.controller.addListener(_onControllerChange);

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && !_isSearchExpanded) {
        setState(() => _isSearchExpanded = true);
      }
    });
  }

  void _onControllerChange() {
    if (widget.controller.isOpen) {
      _animController.forward();
    } else {
      _animController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isSearchExpanded = false;
            _searchQuery = '';
            _searchController.clear();
            _searchFocusNode.unfocus();
          });
        }
      });
    }
    setState(() {});
  }

  void _close() {
    widget.controller.close();
  }

  void _collapseSearch() {
    setState(() {
      _isSearchExpanded = false;
      _searchQuery = '';
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _animController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't render at all when fully closed and animation is done
    if (!widget.controller.isOpen && _animController.isDismissed) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final progress = _slideAnim.value;
        final panelWidth = _isSearchExpanded ? screenWidth : _drawerWidth;
        final translateX = -panelWidth + (panelWidth * progress);

        return Stack(
          children: [
            // ── Scrim ────────────────────────────────────────────────────
            Positioned.fill(
              child: GestureDetector(
                onTap: _isSearchExpanded ? _collapseSearch : _close,
                child: Container(
                  color: Colors.black.withOpacity(0.45 * _scrimAnim.value),
                ),
              ),
            ),

            // ── Drawer Panel ─────────────────────────────────────────────
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: _isSearchExpanded ? screenWidth : _drawerWidth,
              child: Transform.translate(
                offset: Offset(translateX, 0),
                child: _DrawerPanel(
                  isSearchExpanded: _isSearchExpanded,
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  searchQuery: _searchQuery,
                  onSearchChanged: (q) => setState(() => _searchQuery = q),
                  onSearchTap: () => setState(() => _isSearchExpanded = true),
                  onCollapseSearch: _collapseSearch,
                  onClose: _close,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  DRAWER PANEL (the actual content)
// ─────────────────────────────────────────────

class _DrawerPanel extends ConsumerWidget {
  final bool isSearchExpanded;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchTap;
  final VoidCallback onCollapseSearch;
  final VoidCallback onClose;

  const _DrawerPanel({
    required this.isSearchExpanded,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchTap,
    required this.onCollapseSearch,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final conversationsAsync = ref.watch(conversationsProvider);

    // Filter conversations by search query
    final filtered = conversationsAsync.whenData(
      (list) => searchQuery.isEmpty
          ? list
          : list
                .where(
                  (c) =>
                      c.title.toLowerCase().contains(searchQuery.toLowerCase()),
                )
                .toList(),
    );

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.only(top: 1.h, bottom: 1.h, right: 0.4.w , left: 1.h),
              child: Row(
                children: [
                  Expanded(
                    child: _SearchBar(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      onTap: onSearchTap,
                      onChanged: onSearchChanged,
                      isExpanded: isSearchExpanded,
                    ),
                  ),

                  if (isSearchExpanded) ...[
                    GestureDetector(
                      onTap: onCollapseSearch,
                      child: Icon(
                        Icons.cancel,
                        color: theme.hintColor,
                        size: 30,
                      ),
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: () {
                        onClose();
                        ref.read(chatProvider.notifier).startNewChat();
                      },
                      child: Icon(
                        Icons.edit_note_outlined,
                        color: theme.hintColor,
                        size: 28,
                      ),
                    ),
                    
                  ],
                  SizedBox(width: 2.w),
                ],
              ),
            ),

            // ── Section links (hidden in search mode) ───────────────────
            if (!isSearchExpanded) ...[
              _LeadingItem(
                icon: Icons.image_outlined,
                text: 'Images',
                onTap: () {},
              ),
              _LeadingItem(
                icon: Icons.music_note_outlined,
                text: 'AI music',
                onTap: () {},
              ),
              _LeadingItem(
                icon: Icons.terminal_outlined,
                text: 'Code BUD',
                onTap: () {},
              ),
              _LeadingItem(
                icon: Icons.video_camera_back_outlined,
                text: 'AI video',
                onTap: () {},
              ),
              SizedBox(height: 1.h),
            ],

            // ── Search bar ───────────────────────────────────────────────
            SizedBox(height: 1.h),

            // ── Conversations list ────────────────────────────────────────
            Expanded(
              child: filtered.when(
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.h),
                        child: Text(
                          searchQuery.isEmpty
                              ? 'No conversations yet'
                              : 'No results for "$searchQuery"',
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 15.sp,
                            color: theme.secondaryHeaderColor.withOpacity(0.3),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  // Group by time
                  final groups = _groupConversations(conversations);

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 1.h),
                    itemCount: groups.length,
                    itemBuilder: (_, i) {
                      final group = groups[i];
                      return _ConversationGroup(
                        label: group.label,
                        conversations: group.items,
                        onTap: (convo) {
                          onClose();
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Failed to load', style: textTheme.labelSmall),
                ),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────
            const Divider(height: 1, thickness: 0.3),
            _DrawerFooter(onClose: onClose),
          ],
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
//  SEARCH BAR
// ─────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final bool isExpanded;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onTap,
    required this.onChanged,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.5.h, vertical: 0.5.h),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          decoration: BoxDecoration(
            color: theme.canvasColor,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: theme.hintColor.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  style: textTheme.labelMedium,
                  cursorColor: theme.hintColor,
                  decoration: InputDecoration(
                    hintText: 'Search conversations',
                    hintStyle: textTheme.labelMedium?.copyWith(
                      color: theme.hintColor.withOpacity(0.4),
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Icon(
                    Icons.close,
                    color: theme.hintColor.withOpacity(0.5),
                    size: 18,
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
//  CONVERSATION GROUP (with time label)
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
              fontSize: 15.sp,
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
                    fontSize: 15.sp,
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
//  DRAWER FOOTER
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
        userProfile?.fullName ?? userProfile?.userName ?? 'Sign In';
    final imageUrl = userProfile?.imageUrl?.toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        enableFeedback: false,
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          onClose();
            ref
                .read(shellViewProvider.notifier)
                .state = authState.isAuthenticated
                ? ShellView.settings
                : ShellView.onboarding;
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 1.5.h),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.dark,
                backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                    ? NetworkImage(imageUrl)
                    : null,
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? const Icon(
                        Icons.person_3_outlined,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  displayName,
                  style: textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.more_horiz,
                color: theme.secondaryHeaderColor.withOpacity(0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  LEADING ITEM (top nav links)
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
//  BACKWARD COMPAT  (keep old exports alive)
// ─────────────────────────────────────────────

/// Kept so nothing else breaks – you can remove once you've
/// cleaned up old import sites.
class ElvesDrawer extends ConsumerWidget {
  final ElvesDrawerController drawerController;
  const ElvesDrawer({super.key, required this.drawerController});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ElvesDrawerOverlay(controller: drawerController);
}

class DrawerFooter extends ConsumerWidget {
  const DrawerFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _DrawerFooter(onClose: () {});
}
