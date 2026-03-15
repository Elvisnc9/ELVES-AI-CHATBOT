import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:elf_flutter/provider/shellView.dart';

// ─────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────

enum VoiceChatState { idle, listening, speaking }

class VoiceOverlayState {
  final VoiceChatState voiceState;
  final double amplitude;

  const VoiceOverlayState({
    this.voiceState = VoiceChatState.idle,
    this.amplitude = 0.0,
  });

  VoiceOverlayState copyWith({
    VoiceChatState? voiceState,
    double? amplitude,
  }) =>
      VoiceOverlayState(
        voiceState: voiceState ?? this.voiceState,
        amplitude: amplitude ?? this.amplitude,
      );
}

class VoiceOverlayNotifier extends StateNotifier<VoiceOverlayState> {
  VoiceOverlayNotifier() : super(const VoiceOverlayState());

  void startListening() =>
      state = state.copyWith(voiceState: VoiceChatState.listening);

  void startSpeaking() =>
      state = state.copyWith(voiceState: VoiceChatState.speaking);

  void setIdle() =>
      state = state.copyWith(voiceState: VoiceChatState.idle, amplitude: 0.0);

  void reset() => state = const VoiceOverlayState();

  /// Feed STT onSoundLevelChange here. raw is typically –2 to 10 dB.
  void updateAmplitude(double raw) {
    final normalised = ((raw + 2) / 12).clamp(0.0, 1.0);
    state = state.copyWith(amplitude: normalised);
  }
}

final voiceOverlayProvider =
    StateNotifierProvider<VoiceOverlayNotifier, VoiceOverlayState>(
  (_) => VoiceOverlayNotifier(),
);

// ─────────────────────────────────────────────
//  LIQUID RING PAINTER
// ─────────────────────────────────────────────

class LiquidRingPainter extends CustomPainter {
  final double phase;    // primary time  0 → 2π
  final double phase2;   // secondary time (different period = organic)
  final double amplitude;
  final VoiceChatState voiceState;

  // Soap-bubble / holographic palette
  static const List<Color> _iridescent = [
    Color(0xFFFF6EC7), // pink
    Color(0xFF7B2FFF), // violet
    Color(0xFF2979FF), // blue
    Color(0xFF00C6FF), // cyan
    Color(0xFF00FFB3), // mint
    Color(0xFFFFE066), // gold
    Color(0xFFFF6EC7), // close the loop
  ];

  LiquidRingPainter({
    required this.phase,
    required this.phase2,
    required this.amplitude,
    required this.voiceState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseRadius = math.min(cx, cy) * 0.62;

    final activity = voiceState == VoiceChatState.idle
        ? 0.20
        : (0.50 + amplitude * 0.50);

    const int segments = 400;
    const double baseStroke = 20.0;

    // Pre-compute all points so we can draw smooth line segments
    final points = List<Offset>.generate(segments + 1, (i) {
      final t = i / segments;
      final angle = t * 2 * math.pi;
      final wobble = _wobble(angle);
      final r = baseRadius * (1.0 + wobble * activity * 2.4);
      return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    });

    for (int i = 0; i < segments; i++) {
      final t = i / segments;
      final angle = t * 2 * math.pi;

      // Stroke width pulses around the ring
      final thickT = (math.sin(angle * 4 + phase * 1.1) + 1) / 2;
      final stroke = baseStroke * (0.35 + thickT * 0.9) * (0.6 + activity * 0.5);

      // Iridescent color: hue sweeps around ring + drifts over time
      final colorT = (t + phase / (2 * math.pi) * 0.35) % 1.0;
      final color = _lerpColors(_iridescent, colorT);

      // Opacity shimmer
      final opT = (math.sin(angle * 7 - phase * 0.85) + 1) / 2;
      final opacity = voiceState == VoiceChatState.idle
          ? 0.50 + opT * 0.25
          : 0.68 + opT * 0.32;

      // Glow pass (blurred, wider)
      canvas.drawLine(
        points[i],
        points[i + 1],
        Paint()
          ..color = color.withOpacity(opacity * 0.35)
          ..strokeWidth = stroke * 3.2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Sharp pass
      canvas.drawLine(
        points[i],
        points[i + 1],
        Paint()
          ..color = color.withOpacity(opacity)
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Soft inner bloom when active
    if (voiceState != VoiceChatState.idle) {
      canvas.drawCircle(
        Offset(cx, cy),
        baseRadius * 0.80,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withOpacity(0.03 + amplitude * 0.07),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: baseRadius),
          ),
      );
    }
  }

  /// Organic wobble: layered sines so the shape never repeats cleanly
  double _wobble(double angle) {
    return math.sin(angle * 3 + phase) * 0.055 +
        math.sin(angle * 5 - phase2 * 1.3) * 0.038 +
        math.sin(angle * 7 + phase * 0.7) * 0.022 +
        math.sin(angle * 2 - phase2 * 0.5) * 0.032 +
        math.sin(angle * 11 + phase2 * 1.9) * 0.014 +
        math.sin(angle * 13 - phase * 0.4) * 0.010;
  }

  Color _lerpColors(List<Color> colors, double t) {
    final scaled = t * (colors.length - 1);
    final idx = scaled.floor().clamp(0, colors.length - 2);
    return Color.lerp(colors[idx], colors[idx + 1], scaled - idx)!;
  }

  @override
  bool shouldRepaint(LiquidRingPainter old) =>
      old.phase != phase ||
      old.phase2 != phase2 ||
      old.amplitude != amplitude ||
      old.voiceState != voiceState;
}

// ─────────────────────────────────────────────
//  ANIMATED LIQUID RING
// ─────────────────────────────────────────────

class AnimatedLiquidRing extends StatefulWidget {
  final double amplitude;
  final VoiceChatState voiceState;
  final double size;

  const AnimatedLiquidRing({
    super.key,
    required this.amplitude,
    required this.voiceState,
    this.size = 280,
  });

  @override
  State<AnimatedLiquidRing> createState() => _AnimatedLiquidRingState();
}

class _AnimatedLiquidRingState extends State<AnimatedLiquidRing>
    with TickerProviderStateMixin {
  late final AnimationController _primary;
  late final AnimationController _secondary;

  @override
  void initState() {
    super.initState();
    // Two controllers with non-harmonic periods → always looks organic
    _primary = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();

    _secondary = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5300),
    )..repeat();
  }

  @override
  void dispose() {
    _primary.dispose();
    _secondary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_primary, _secondary]),
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: LiquidRingPainter(
          phase: _primary.value * 2 * math.pi,
          phase2: _secondary.value * 2 * math.pi,
          amplitude: widget.amplitude,
          voiceState: widget.voiceState,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FULL-SCREEN VOICE PAGE
// ─────────────────────────────────────────────

class VoiceChatOverlay extends ConsumerStatefulWidget {
  const VoiceChatOverlay({super.key});

  @override
  ConsumerState<VoiceChatOverlay> createState() => _VoiceChatOverlayState();
}

class _VoiceChatOverlayState extends ConsumerState<VoiceChatOverlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceOverlayProvider.notifier).startListening();
    });
  }

  @override
  void dispose() {
    ref.read(voiceOverlayProvider.notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceOverlayProvider);
    final notifier = ref.read(voiceOverlayProvider.notifier);
    final theme = Theme.of(context);

    final statusLabel = switch (state.voiceState) {
      VoiceChatState.listening => 'Listening…',
      VoiceChatState.speaking  => 'Speaking…',
      VoiceChatState.idle      => 'Tap mic to speak',
    };

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // ── top bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      notifier.reset();
                      ref.read(shellViewProvider.notifier).state = ShellView.chat;
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.canvasColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: theme.hintColor, size: 22),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const Spacer(),

            // ── liquid ring ──────────────────────────────
            AnimatedLiquidRing(
              amplitude: state.amplitude,
              voiceState: state.voiceState,
              size: 290,
            ),

            const SizedBox(height: 44),

            // ── status label ─────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                statusLabel,
                key: ValueKey(statusLabel),
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.0,
                  color: theme.hintColor.withOpacity(0.5),
                ),
              ),
            ),

            const Spacer(),

            // ── mic button ───────────────────────────────
            _MicButton(
              voiceState: state.voiceState,
              onTap: () {
                if (state.voiceState == VoiceChatState.listening) {
         
                  notifier.setIdle();
                } else {
                 
                  notifier.startListening();
                }
              },
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MIC BUTTON
// ─────────────────────────────────────────────

class _MicButton extends StatefulWidget {
  final VoiceChatState voiceState;
  final VoidCallback onTap;
  const _MicButton({required this.voiceState, required this.onTap});

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 1.0,
      upperBound: 1.22,
    );
    if (widget.voiceState == VoiceChatState.listening) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    if (widget.voiceState == VoiceChatState.listening) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.animateTo(1.0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isListening = widget.voiceState == VoiceChatState.listening;
    final isSpeaking  = widget.voiceState == VoiceChatState.speaking;

    return GestureDetector(
      onTap: isSpeaking ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            if (isListening)
              Transform.scale(
                scale: _pulse.value,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF7B2FFF).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening
                    ? const Color(0xFF7B2FFF)
                    : theme.canvasColor,
                boxShadow: isListening
                    ? [
                        BoxShadow(
                          color: const Color(0xFF7B2FFF).withOpacity(0.5),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                isSpeaking ? Icons.volume_up_outlined : Icons.mic,
                color: isListening ? Colors.white : theme.hintColor,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}