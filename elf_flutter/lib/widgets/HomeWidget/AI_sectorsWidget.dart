import 'package:elf_flutter/shared/theme.dart';
import 'package:flutter/material.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

class Sectors extends StatelessWidget {
   const Sectors(
    {
    super.key, 
    required this.icon, 
    required this.title,
    required this.Subtitle,
     required this.onPressed, 
     required this.height,
      required this.width, 
      required this.color, 
      required this.size,
      
       this.textColor = AppColors.dark
  });

  final Color color;
  final IconData icon;
  final double height;
  final double width;
  final String title;
  final String Subtitle;
  final VoidCallback onPressed;
  final double size;
  final Color textColor ;

  @override
  Widget build(BuildContext context) {
    return Material(
       color: color,
       borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onPressed,
         borderRadius: BorderRadius.circular(25),
        child: SizedBox(
          height: height,
          width: width,
          child: Padding(
            padding:  EdgeInsets.only(left: 1.5.h, top: 1.h,right: 0.5.h, bottom:1.5.h ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black.withOpacity(0.2),
                      child: Icon(icon, color: textColor, size: 20)),
                      
        
                      Spacer(),
                      Icon(Icons.arrow_outward, color: textColor, size: 20)
                  ],
                ),
        
                Spacer(),
        
                Text(
                  title,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: size,
                    color: textColor,
                    fontWeight: FontWeight.w400,
                    height: 1.1
                  ),
                ),

                SizedBox(height: 0.5.h,),

                 Text(
                  Subtitle,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 10.sp,
                    color: textColor.withOpacity(0.7),
                  ),
                 ),
                
               
                  
              ]),
          )
          ),
      ),
    );
  }
}