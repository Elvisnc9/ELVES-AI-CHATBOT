import 'package:elf_flutter/screens/chatScreen.dart';
import 'package:elf_flutter/shared/theme.dart';
import 'package:elf_flutter/state/shellView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});

  @override
  ConsumerState<Settings> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<Settings> {
  final String? profileImage = null;


  bool generateVideosForImages = false;
  bool autoplayVideosInFeed = false;
  bool hapticsOnButtons = false;
  bool hapticsOnResponse = false;

  final List<String> socialIconAssetPaths = [];

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    final Texttheme = Theme.of(context).textTheme;
    final Themee = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.h),
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: HeroButton(
             child:  Icon( Icons.arrow_back,),
              onPressed: () {
                ref.read(shellViewProvider.notifier).state = ShellView.home;
              },
            ),
          ),
      
          
      
          _buildProfileHeader(),
      
          SizedBox(height: 2.h),
      
          sectionHeader('Subscription'),
          SizedBox(height: 1.h),
          _subscriptionTile(),
      
          SizedBox(height: 2.h),
      
          sectionHeader('Appearance'),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2.h),
            decoration: BoxDecoration(color: Themee.canvasColor,
            borderRadius: BorderRadius.circular(20),),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _appearanceChip(label: 'System', mode: ThemeMode.system, currentTheme: theme, icon: Icons.tune, onTap:(){
                  ref.read(themeControllerProvider.notifier).setSystem();
                } ),
      
                _appearanceChip(
                  label: 'Dark',
                  mode: ThemeMode.dark,
                  currentTheme: theme,
                  icon: Icons.nightlight_round,
                   onTap:(){
                  ref.read(themeControllerProvider.notifier).setDark();
                }
                ),
                _appearanceChip(
                  label: 'Light',
                  mode: ThemeMode.light,
                  currentTheme: theme,
                  icon: Icons.wb_sunny_outlined,
                   onTap:(){
                  ref.read(themeControllerProvider.notifier).setLight();
                }
                )
              ],
            ),).animate().fadeIn().slideX(begin: -0.3),
          
          SizedBox(height: 2.h),
      
          sectionHeader('Haptics & Vibration'),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Themee.canvasColor,
              borderRadius: BorderRadius.circular(20)
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'When pressing buttons',
                    style: Texttheme.labelMedium?.copyWith(color: Themee.secondaryHeaderColor),
                  ),
                  value: hapticsOnButtons,
                  onChanged: (v) => setState(() => hapticsOnButtons = v),
                  secondary: Icon(Icons.touch_app_outlined, color: Themee.secondaryHeaderColor),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                
                  activeColor: Colors.white,
                
                  activeTrackColor: Themee.secondaryHeaderColor,
                
                  inactiveThumbColor: Colors.grey.shade700,
                
                  inactiveTrackColor: Colors.white,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'When Genie is responding',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Themee.secondaryHeaderColor),
                  ),
                  value: hapticsOnResponse,
                  onChanged: (v) => setState(() => hapticsOnResponse = v),
                  secondary: Icon(Icons.smart_toy_outlined, color: Themee.secondaryHeaderColor),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                
                  activeColor: Colors.white,
                
                  activeTrackColor: Themee.secondaryHeaderColor,
                
                  inactiveThumbColor: Colors.grey.shade700,
                
                  inactiveTrackColor: Colors.white,
                ),
              ],
            ),
          ).animate().fadeIn().slideX(begin: 0.3),
      
          SizedBox(height: 2.h),
      
          sectionHeader('Data & Information'),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Themee.canvasColor,
            borderRadius: BorderRadius.circular(20)
          
            ),
      
            child: Column(
              children: [
                NavigationTile( icon: Icons.tune, text: 'Customize Genie', onTap: () {}),
                NavigationTile( icon: Icons.storage, text: 'Data Controls', onTap: () {}),
                NavigationTile( icon: Icons.privacy_tip_outlined, text: 'Privacy Policy', onTap: () {}),
                
                NavigationTile( icon: Icons.report_problem_outlined, text: 'Report Issue', onTap: () {}),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.3),
      
          SizedBox(height: 2.h),
      
          TextButton(onPressed: (){}, child: Text('LogOut',
          style: Texttheme.labelMedium?.copyWith(color: Colors.red),
          ))
      
        ],
      ),
    );
  }











  Widget _buildProfileHeader() {
    final Texttheme = Theme.of(context).textTheme;
    final Themee = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Themee.canvasColor,
                    child: ClipOval(
                      child: SizedBox(
                        width: 104,
                        height: 104,
                        child: _buildProfileImage(),
                      ),
                    ),
                  ),

                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Edit profile tapped')),
                        );
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Themee.canvasColor,
                        child: Icon(Icons.edit, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text('Elvis', style: Texttheme.labelMedium),
              SizedBox(height: 6),
              Text(
                'elvisnonso@gmail.com',
                style: Texttheme.labelMedium?.copyWith(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    if (profileImage == null) {
      return Container(
        color: Colors.transparent,
        child: Center(
          child: Icon(Icons.person, size: 48, color: Colors.grey[700]),
        ),
      );
    } else if (profileImage!.startsWith('http')) {
      return Image.network(
        profileImage!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Center(
            child: Icon(Icons.person, size: 48, color: Colors.grey[700]),
          );
        },
      );
    } else {
      return Image.asset(profileImage!, fit: BoxFit.cover);
    }
  }

  Widget sectionHeader(String text) {
    final Texttheme = Theme.of(context).textTheme;
    return Text(text, style: Texttheme.labelLarge);
  }

  Widget _appearanceChip({
    required String label,
    required ThemeMode mode,
    required ThemeMode currentTheme,
    required VoidCallback onTap,
    IconData? icon,


  }) {
    final bool selected = currentTheme == mode;
     final Texttheme = Theme.of(context).textTheme;
     final Themee = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ChoiceChip(
        avatar:
            icon != null
                ? Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.black : Colors.white,
                )
                : null,
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        
        selectedColor: Colors.white,
        backgroundColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        labelStyle: Texttheme.labelMedium?.copyWith(color: selected? Colors.black: Colors.white),
        elevation: 0,
        side: BorderSide(color: Themee.secondaryHeaderColor,),
      ),
    );
  }




  Widget _subscriptionTile() {
    final Texttheme = Theme.of(context).textTheme;
        final Themee = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Themee.canvasColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.shield, color: Colors.yellow),
      ),
      title: Text(
        'Upgrade to SuperGenie',
        style: Texttheme.labelMedium?.copyWith(color: Themee.secondaryHeaderColor),
      ),
      onTap: () {},
    );
  }
}

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
    final Texttheme = Theme.of(context).textTheme;
        final Themee = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 0.2.h, vertical: 0.5.h),
      leading: Icon(icon, color: Themee.secondaryHeaderColor),
      title: Text(
        text,
        style: Texttheme.labelMedium?.copyWith(color: Themee.secondaryHeaderColor),
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