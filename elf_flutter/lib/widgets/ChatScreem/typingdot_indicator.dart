import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';

/// 🔵 SINGLE SCALING DOT
/// Smooth breathing / thinking animation

class ScalingTypingDot extends StatefulWidget {
 
  final double dotSize;
  final Duration duration;

  const ScalingTypingDot({
    super.key,
    this.dotSize = 25,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<ScalingTypingDot> createState() => _ScalingTypingDotState();
}

class _ScalingTypingDotState extends State<ScalingTypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.8 + (math.sin(_controller.value * math.pi * 2) + 1) / 4;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.dotSize,
            height: widget.dotSize,
            decoration: BoxDecoration(
              color: theme.hintColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scaleXY(begin: 0.8, end: 1);
  }
}
