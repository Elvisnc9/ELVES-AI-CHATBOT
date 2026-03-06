import 'package:elf_flutter/screens/chatScreen.dart';
import 'package:elf_flutter/widgets/ChatScreem/DrawerSearchBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

import 'package:elf_flutter/widgets/HomeWidget/AI_sectorsWidget.dart';
import 'package:elf_flutter/widgets/ChatScreem/chatModels.dart';
import 'package:elf_flutter/shared/theme.dart';
import 'package:elf_flutter/state/auth_state.dart';
import 'package:elf_flutter/state/shellView.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
   // final status = ref.watch(homeStatusProvider);
    return AnimatedSwitcher(
      duration: 300.ms,
      child: HomeContent(key: ValueKey('content')),
    );
  }
}




// class HomeSkeleton extends StatelessWidget {
//   const HomeSkeleton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SkeletonBox(height: 26, width: 220).shimmer(),
//           const SizedBox(height: 20),
//           const SkeletonBox(height: 50).shimmer(),
//           const SizedBox(height: 30),
//           Row(
//             children:
//                 const [
//                   Expanded(child: SkeletonBox(height: 120)),
//                   SizedBox(width: 12),
//                   Expanded(child: SkeletonBox(height: 120)),
//                 ].map((e) => e.shimmer()).toList(),
//           ),
//         ],
//       ),
//     );
//   }
// }

class HomeContent extends ConsumerStatefulWidget {
  const HomeContent({super.key});

  @override
  ConsumerState<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeContent> {

 


  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    // final authNotifier = ref.read(authControllerProvider.notifier);
      final TextEditingController myController = TextEditingController();
    final FocusNode myFocusNode = FocusNode();


    ImageProvider avatar;
   
      avatar = const AssetImage('assets/google_Logo.png');
      final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        
        children: [
          
          SizedBox(height: 1.h),
      
          
         
      
                
      
           SizedBox(height: 7.h ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Sectors(
                  icon: Icons.chat,
                  textColor: AppColors.dark,
                  title: 'Chat\n With AI',
                  Subtitle: 'Talk to your AI assistant and get instant answers, smart suggestions, and real-time support.',
                  onPressed: () {
                      ref.read(shellViewProvider.notifier).state = ShellView.chat;
                  },
                  height: 30.h,
                  width: 47.w,
                  color: Color(0xFFADFF2F),
                  
                  size: 35.sp,
                ).animate().fadeIn().slideX(begin: -0.3 ,delay: 200.ms ),
            
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Sectors(
                        icon: Icons.image,
                        title: 'Create AI Images',
                        Subtitle: 'Generate stunning images with AI',
                        onPressed: () {},
                        height: 15.h,
                        width: 45.w,
                         textColor: Colors.white,
                        color: AppColors.primary,
                        size: 16.sp,
                      ).animate().fadeIn().slideY(begin: -0.3, delay: 200.ms),
                      SizedBox(height: 1.h),
            
                      Sectors(
                        icon: Icons.video_call_rounded,
                        title: 'Create AI Videos',
                        Subtitle: 'Generate stunning videos with AI',
                        onPressed: () {},
                        height: 15.h,
                        width: 45.w,
                        color: Color(0xFFF1DDCF),
                        size: 16.sp,
                      ).animate().fadeIn().slideY(begin: 0.3, delay: 200.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
            
      
            SizedBox( height: 8.h,
            ),
      
            PremiumFloatingChips(),
      
            
      
         
        //   ListView.builder(
        //     scrollDirection: Axis.vertical,
        //     shrinkWrap: true,
        //     physics: NeverScrollableScrollPhysics(),
        //     itemCount: ChatList.length,
        //     itemBuilder: (context, index) {
        //       return RecentChats(model: ChatList[index]);
        //     },
            
            
        //   )
      
      
      
       
         ],
      ),
    );
  }
}





class RowTitle extends StatelessWidget {
  const RowTitle({super.key, required this.textTheme, required this.title});

  final TextTheme textTheme;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 0.5.h),
      child: Row(
        children: [
          Text(
            title,
            style: textTheme.displayMedium?.copyWith(
              fontSize: 28.sp,
            ),
          ),

      
        
        ],
      ),
    );
  }
}




class ProfileImageButton extends StatelessWidget {
  const ProfileImageButton({super.key, required this.onPressed, required this.image});
   final VoidCallback onPressed;
  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: EdgeInsets.all(1.5.h),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.light, width: 0.9),
          ),
          child: Image(image: image, width: 10, fit: BoxFit.contain,)
        ),
      ),
    ); 
  }
}