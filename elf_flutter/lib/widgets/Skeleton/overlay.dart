import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  bool _isGhostMode = false;

  void _activateGhostMode() {
    GhostModeTransition.show(
      context: context,
      onTransitionComplete: () {
        setState(() {
          _isGhostMode = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isGhostMode ? const GhostModeScreen() : _buildOnboardingUI(),
    );
  }

  Widget _buildOnboardingUI() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
            const Color(0xFF0F3460),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: _activateGhostMode,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.bubble_chart,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: const RadialGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                        ),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4ECDC4).withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Discover the\nInvisible',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap the ghost icon to enter Ghost Mode\nand experience the unseen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.6),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class GhostModeTransition {
  static OverlayEntry? _overlayEntry;
  static AnimationController? _controller;

  static void show({
    required BuildContext context,
    required VoidCallback onTransitionComplete,
  }) {
    final overlay = Overlay.of(context);
    
    _controller = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 2400),
    );

    _overlayEntry = OverlayEntry(
      builder: (context) => GhostModeTransitionWidget(
        controller: _controller!,
        onComplete: () {
          _removeOverlay();
          onTransitionComplete();
        },
      ),
    );

    overlay.insert(_overlayEntry!);
    _controller!.forward();
  }

  static void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _controller?.dispose();
    _controller = null;
  }
}




class GhostModeTransitionWidget extends StatefulWidget {
  final AnimationController controller;
  final VoidCallback onComplete;

  const GhostModeTransitionWidget({
    super.key,
    required this.controller,
    required this.onComplete,
  });

  @override
  State<GhostModeTransitionWidget> createState() => _GhostModeTransitionWidgetState();
}

class _GhostModeTransitionWidgetState extends State<GhostModeTransitionWidget> 
    with TickerProviderStateMixin {
  
  late final Animation<double> _ghostExpandAnimation;
  late final Animation<double> _backgroundDarkenAnimation;
  late final Animation<double> _energyPulseAnimation;
  late final Animation<double> _borderGlowAnimation;
  late final Animation<double> _flashAnimation;
  late final Animation<double> _transitionAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
    
    widget.controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 200), widget.onComplete);
      }
    });
  }

  void _setupAnimations() {
    const curve = Curves.easeOutExpo;
    const cubicCurve = Cubic(0.65, 0, 0.35, 1); 

    
    _ghostExpandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.0, 0.30, curve: curve),
      ),
    );

    
    _backgroundDarkenAnimation = Tween<double>(begin: 0.0, end: 0.7).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.05, 0.40, curve: Curves.easeInOutCubic),
      ),
    );

    
    _energyPulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.20, 0.60, curve: cubicCurve),
      ),
    );

    
    _borderGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.25, 0.70, curve: Curves.easeInOutCubic),
      ),
    );

    
    _flashAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.45, 0.55, curve: Curves.easeInOutCubic),
      ),
    );

    
    _transitionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.60, 1.0, curve: curve),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Stack(
          children: [
            
            _buildDarkeningBackground(),

            
            ..._buildEnergyPulses(),

            
            _buildExpandingGhost(),

            
            _buildGlowingBorder(),

            
            _buildFlashBurst(),

            
            _buildCinematicTransition(),
          ],
        );
      },
    );
  }

  Widget _buildDarkeningBackground() {
    return Container(
      color: Colors.black.withOpacity(_backgroundDarkenAnimation.value),
    );
  }

  List<Widget> _buildEnergyPulses() {
    final pulses = <Widget>[];
    final pulseValue = _energyPulseAnimation.value;
    
    
    for (int i = 0; i < 3; i++) {
      final delay = i * 0.15;
      final adjustedValue = ((pulseValue - delay) / (1 - delay * 2)).clamp(0.0, 1.0);
      
      if (adjustedValue > 0) {
        pulses.add(
          Positioned.fill(
            child: CustomPaint(
              painter: EnergyPulsePainter(
                progress: adjustedValue,
                color: Colors.white.withOpacity(0.3 - (i * 0.08)),
                strokeWidth: 3 - i.toDouble(),
              ),
            ),
          ),
        );
      }
    }
    
    return pulses;
  }

  Widget _buildExpandingGhost() {
    final expandValue = _ghostExpandAnimation.value;
    final size = 48.0 + (expandValue * MediaQuery.of(context).size.width * 1.2);
    final opacity = 1.0 - (expandValue * 0.3);
    
    
    final screenSize = MediaQuery.of(context).size;
    final beginPosition = Offset(screenSize.width - 60, 60); 
    final endPosition = Offset(screenSize.width / 2, screenSize.height / 2);
    final currentPosition = Offset.lerp(beginPosition, endPosition, expandValue)!;

    return Positioned(
      left: currentPosition.dx - size / 2,
      top: currentPosition.dy - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(opacity),
              Colors.white.withOpacity(opacity * 0.5),
              Colors.transparent,
            ],
            stops: const [0.3, 0.6, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.5 * expandValue),
              blurRadius: 50 * expandValue,
              spreadRadius: 20 * expandValue,
            ),
          ],
        ),
        child: Icon(
          Icons.bubble_chart,
          size: 24 + (expandValue * 100),
          color: Colors.white.withOpacity(opacity),
        ),
      ),
    );
  }

  Widget _buildGlowingBorder() {
    final glowValue = _borderGlowAnimation.value;
    
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, child) {
            return CustomPaint(
              painter: GlowingBorderPainter(
                progress: glowValue,
                glowColor: Colors.white,
                pulseSpeed: widget.controller.value,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }

  Widget _buildFlashBurst() {
    final flashValue = _flashAnimation.value;
    
    if (flashValue <= 0) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Colors.white.withOpacity(flashValue),
              Colors.white.withOpacity(flashValue * 0.5),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20 * flashValue, sigmaY: 20 * flashValue),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _buildCinematicTransition() {
    final transitionValue = _transitionAnimation.value;
    
    if (transitionValue <= 0) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0F).withOpacity(transitionValue),
        ),
        child: Transform.scale(
          scale: 1.0 + (transitionValue * 0.1),
          child: Opacity(
            opacity: transitionValue,
            child: const GhostModePreview(),
          ),
        ),
      ),
    );
  }
}




class EnergyPulsePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  EnergyPulsePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final currentRadius = maxRadius * progress;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * (1 - progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    
    for (int i = 0; i < 2; i++) {
      final ringRadius = currentRadius - (i * 30);
      if (ringRadius > 0) {
        canvas.drawCircle(center, ringRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant EnergyPulsePainter oldDelegate) => true;
}

class GlowingBorderPainter extends CustomPainter {
  final double progress;
  final Color glowColor;
  final double pulseSpeed;

  GlowingBorderPainter({
    required this.progress,
    required this.glowColor,
    required this.pulseSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(0));
    
    
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        glowColor.withOpacity(0),
        glowColor.withOpacity(progress * 0.8),
        glowColor.withOpacity(progress),
        glowColor.withOpacity(progress * 0.8),
        glowColor.withOpacity(0),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      transform: GradientRotation(pulseSpeed * 2 * math.pi),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * progress
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 20 * progress);

    canvas.drawRRect(rrect, paint);
    
    
    final innerPaint = Paint()
      ..color = glowColor.withOpacity(progress * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * progress
      ..maskFilter = MaskFilter.blur(BlurStyle.inner, 10 * progress);
      
    canvas.drawRRect(rrect.deflate(2), innerPaint);
  }

  @override
  bool shouldRepaint(covariant GlowingBorderPainter oldDelegate) => true;
}




class GhostModeScreen extends StatefulWidget {
  const GhostModeScreen({super.key});

  @override
  State<GhostModeScreen> createState() => _GhostModeScreenState();
}

class _GhostModeScreenState extends State<GhostModeScreen> 
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          
          Positioned.fill(
            child: CustomPaint(
              painter: AmbientBackgroundPainter(),
            ),
          ),
          
          
          SafeArea(
            child: Column(
              children: [
                
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bubble_chart,
                              size: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'GHOST MODE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _floatAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: child,
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFFE0E0E0),
                                  Color(0xFF9E9E9E),
                                  Color(0xFF616161),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 60,
                                  spreadRadius: 20,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 100,
                                  spreadRadius: 40,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.bubble_chart,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'I\'m here, unseen',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'How may I assist you anonymously?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.5),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GhostModePreview extends StatelessWidget {
  const GhostModePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0F),
      child: const Center(
        child: Icon(
          Icons.bubble_chart,
          size: 80,
          color: Colors.white24,
        ),
      ),
    );
  }
}

class AmbientBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, -0.3),
        radius: 0.8,
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}