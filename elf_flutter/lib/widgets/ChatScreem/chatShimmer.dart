import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

Widget chatBubbleShimmer({required bool isUser}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: isUser ? 8 : 0),
    child: Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        height: 5.h,
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: isUser ? 75.w : 100.w,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
        ),
       
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1500.ms,
          color: Colors.white,
        ),
  );
}
Widget chatShimmerList() {
  return ListView.builder(
    reverse: true,
    padding: EdgeInsets.only(
      top: 20.h,
      bottom: 5.h,
      left: 12,
      right: 12,
    ),
    itemCount: 12,
    itemBuilder: (_, index) {
      final isUser = index % 2 == 0;
      return chatBubbleShimmer(isUser: isUser);
    },
  );
}