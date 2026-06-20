import 'package:elf_flutter/provider/auth_state.dart';
import 'package:elf_flutter/provider/chatState.dart';
import 'package:elf_flutter/shared/theme.dart';
import 'package:elf_flutter/provider/shellView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});

  @override
  ConsumerState<Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  bool hapticsOnButtons = false;
  bool hapticsOnResponse = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final userProfile = authState.userProfile;

    final String displayName =  userProfile?.userName ?? 'Elvis Ngwu' ;
    final email = userProfile?.email ?? '';
    final imageUrl = userProfile?.imageUrl?.toString();

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.h),
        children: [
          // ── Back ─────────────────────────────────────────────────────────
          Align(
            alignment: Alignment.topLeft,
            child: HeroButton(
              child: const Icon(Icons.arrow_back),
              onPressed: (){
              ref.read(inputAutofocusProvider.notifier).state = true;
ref.read(shellViewProvider.notifier).state = ShellView.chat;}
            ),
          ),

          // ── Profile header ────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: theme.canvasColor,
                  child: ClipOval(
                    child: SizedBox(
                      width: 104,
                      height: 104,
                      child: _profileImage(imageUrl),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(displayName, style: textTheme.labelMedium),
                const SizedBox(height: 6),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: textTheme.labelMedium?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                // Sign-in prompt for guests
               
                
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // ── Appearance ────────────────────────────────────────────────────
          _sectionHeader('Appearance'),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2.h),
            decoration: BoxDecoration(
              color: theme.canvasColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _chip(
                  label: 'System',
                  mode: ThemeMode.system,
                  current: themeMode,
                  icon: Icons.tune,
                  onTap: () =>
                      ref.read(themeControllerProvider.notifier).setSystem(),
                ),
                _chip(
                  label: 'Dark',
                  mode: ThemeMode.dark,
                  current: themeMode,
                  icon: Icons.nightlight_round,
                  onTap: () =>
                      ref.read(themeControllerProvider.notifier).setDark(),
                ),
                _chip(
                  label: 'Light',
                  mode: ThemeMode.light,
                  current: themeMode,
                  icon: Icons.wb_sunny_outlined,
                  onTap: () =>
                      ref.read(themeControllerProvider.notifier).setLight(),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // ── Haptics ───────────────────────────────────────────────────────
          _sectionHeader('Haptics & Vibration'),
          SizedBox(height: 1.h),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.canvasColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _hapticTile(
                  'When pressing buttons',
                  Icons.touch_app_outlined,
                  hapticsOnButtons,
                  (v) => setState(() => hapticsOnButtons = v),
                ),
                _hapticTile(
                  'When Genie is responding',
                  Icons.smart_toy_outlined,
                  hapticsOnResponse,
                  (v) => setState(() => hapticsOnResponse = v),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // ── Data & Info ───────────────────────────────────────────────────
          _sectionHeader('Data & Information'),
          SizedBox(height: 1.h),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.canvasColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                NavigationTile(
                    icon: Icons.tune,
                    text: 'Customize Genie',
                    onTap: () {}),
                NavigationTile(
                    icon: Icons.storage,
                    text: 'Data Controls',
                    onTap: () {}),
                NavigationTile(
                    icon: Icons.privacy_tip_outlined,
                    text: 'Privacy Policy',
                    onTap: () {}),
                NavigationTile(
                    icon: Icons.report_problem_outlined,
                    text: 'Report Issue',
                    onTap: () {}),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // ── Sign out / Sign in ────────────────────────────────────────────
          if (authState.isAuthenticated)
            TextButton(
              onPressed: _confirmSignOut,
              child: Text(
                'Sign Out',
                style: textTheme.labelMedium?.copyWith(color: Colors.red),
              ),
            )
          else
            TextButton(
              onPressed: () => ref
                  .read(shellViewProvider.notifier)
                  .state = ShellView.onboarding,
              child: Text(
                'Sign In',
                style:
                    textTheme.labelMedium?.copyWith(color: AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign out?', style: textTheme.displayMedium),
        content: Text(
          'You can still use the app as a guest after signing out.',
          style: textTheme.labelMedium
              ?.copyWith(color: theme.secondaryHeaderColor.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: textTheme.labelMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sign out',
                style: textTheme.labelMedium?.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  Widget _profileImage(String? url) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Center(child: Icon(Icons.person, size: 48, color: Colors.grey[700])),
      );
    }
    return Container(
      color: Colors.transparent,
      child:
          Center(child: Icon(Icons.person, size: 48, color: Colors.grey[700])),
    );
  }

  Widget _sectionHeader(String text) =>
      Text(text, style: Theme.of(context).textTheme.labelLarge);

  Widget _hapticTile(
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: theme.secondaryHeaderColor),
      ),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: theme.secondaryHeaderColor),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      activeColor: Colors.white,
      activeTrackColor: theme.secondaryHeaderColor,
      inactiveThumbColor: Colors.grey.shade700,
      inactiveTrackColor: Colors.white,
    );
  }

  Widget _chip({
    required String label,
    required ThemeMode mode,
    required ThemeMode current,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final selected = current == mode;
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ChoiceChip(
        avatar: icon != null
            ? Icon(icon,
                size: 18, color: selected ? Colors.black : Colors.white)
            : null,
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.white,
        backgroundColor:selected? theme.scaffoldBackgroundColor : Colors.black.withOpacity(0.8) ,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        labelStyle: textTheme.labelMedium
            ?.copyWith(color: selected ? Colors.black : Colors.white),
        elevation: 0,
        side: BorderSide(color: theme.secondaryHeaderColor),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED WIDGETS (kept here so imports don't break)
// ─────────────────────────────────────────────

class NavigationTile extends StatelessWidget {
  const NavigationTile({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding:
          EdgeInsets.symmetric(horizontal: 0.2.h, vertical: 0.5.h),
      leading: Icon(icon, color: theme.secondaryHeaderColor),
      title: Text(
        text,
        style: theme.textTheme.labelMedium
            ?.copyWith(color: theme.secondaryHeaderColor),
      ),
      onTap: onTap,
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