import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

class PremiumFloatingChips extends StatefulWidget {
  const PremiumFloatingChips({super.key});

  @override
  State<PremiumFloatingChips> createState() => _PremiumFloatingChipsState();
}

class _PremiumFloatingChipsState extends State<PremiumFloatingChips>
    with TickerProviderStateMixin {
  final List<ScrollController> _controllers =
      List.generate(4, (_) => ScrollController());

  late List<Timer> _timers;
  late AnimationController _floatController;

  final List<List<String>> data = [
    ["Can you help me debug this code?", "Elon Networth",
     "What’s a good startup?", "Technnologies"],
    ["How do I Create a Startup", "Mathematics",
     "frontend and backend development?", "Iran Bombing"],
  ];

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
      lowerBound: -6,
      upperBound: 6,
    )..repeat(reverse: true);

    _timers = [
      _autoScroll(0, 0.7, false), // left
      _autoScroll(1, 1.0, true),  // right
      _autoScroll(2, 0.4, false), // slower left
      _autoScroll(3, 1.3, true),  // faster right
    ];
  }

 Timer _autoScroll(int index, double speed, bool reverse) {
  return Timer.periodic(const Duration(milliseconds: 16), (_) async {
    final controller = _controllers[index];
    if (!controller.hasClients) return;

    final maxScroll = controller.position.maxScrollExtent / 2;

    double newOffset =
        controller.offset + (reverse ? -speed : speed);

    if (newOffset >= maxScroll) {
      controller.jumpTo(0);
    } else if (newOffset <= 0) {
      controller.jumpTo(maxScroll);
    } else {
      controller.jumpTo(newOffset);
    }
  });
}

  @override
  void dispose() {
    for (var timer in _timers) {
      timer.cancel();
    }
    for (var c in _controllers) {
      c.dispose();
    }
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(2, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildRow(index),
          );
        })
      ],
    );
  }

  Widget _buildRow(int index) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return  ShaderMask(
  shaderCallback: (Rect bounds) {
    return const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        Colors.black,
        Colors.black,
        Colors.transparent,
      ],
      stops: [0.0, 0.1, 0.9, 1.0],
    ).createShader(bounds);
  },
  blendMode: BlendMode.dstIn,
  child: SizedBox(
        height: 45,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                index.isEven ? _floatController.value * 0.5 : 0,
                _floatController.value * (index + 1) * 0.15,
              ),
              child: child,
            );
          },
          child: ListView.builder(
            controller: _controllers[index],
            scrollDirection: Axis.horizontal,
            itemCount: data[index].length * 2,
            itemBuilder: (context, i) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16,),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400.withOpacity(0.15), // ash
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.grey.shade500,
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                         data[index][i % data[index].length],
                          style:  textTheme.labelMedium
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
