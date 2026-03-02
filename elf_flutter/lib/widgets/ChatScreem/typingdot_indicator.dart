import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 🔥 PURE BOUNCING DOTS ONLY (No bubble, No scaling)
/// Exactly what you asked for — just three dots bouncing freely
/// Super smooth, staggered, natural WhatsApp-style bounce

class BouncingTypingDots extends StatefulWidget {
  final Color dotColor;
  final double dotSize;
  final double spacing;
  final Duration duration;

  const BouncingTypingDots({
    super.key,
    this.dotColor = const Color(0xFF8A8A8A), // WhatsApp grey
    this.dotSize = 7.0,
    this.spacing = 4.0,
    this.duration = const Duration(milliseconds: 1550),
  });

  @override
  State<BouncingTypingDots> createState() => _BouncingTypingDotsState();
}

class _BouncingTypingDotsState extends State<BouncingTypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(); // Infinite smooth loop
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index < 2 ? widget.spacing : 0),
          child: _BouncingDot(
            controller: _controller,
            delay: index * 0.40,        // Perfect natural stagger
            color: widget.dotColor,
            size: widget.dotSize,
          ),
        );
      }),
    );
  }
}

class _BouncingDot extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Color color;
  final double size;

  const _BouncingDot({
    required this.controller,
    required this.delay,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Clean sine wave bounce with natural easing
        final phase = (controller.value + delay) % 1.0;
        final bounce = (math.sin(phase * math.pi * 3.9) + 1) / 2;

        // Pure vertical bounce — no scaling at all
        final yOffset = -8.0 * Curves.easeOutCubic.transform(bounce);

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}