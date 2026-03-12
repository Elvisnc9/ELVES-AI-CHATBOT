import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:elf_flutter/shared/theme.dart';

// ─────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────

enum VoiceChatState { idle, listening, speaking }

class VoiceOverlayState {
  final bool isVisible;
  final VoiceChatState voiceState;

  /// 0.0 – 1.0  amplitude fed from STT volume callbacks
  final double amplitude;

  const VoiceOverlayState({
    this.isVisible = false,
    this.voiceState = VoiceChatState.idle,
    this.amplitude = 0.0,
  });

  VoiceOverlayState copyWith({
    bool? isVisible,
    VoiceChatState? voiceState,
    double? amplitude,
  }) =>
      VoiceOverlayState(
        isVisible: isVisible ?? this.isVisible,
        voiceState: voiceState ?? this.voiceState,
        amplitude: amplitude ?? this.amplitude,
      );
}

class VoiceOverlayNotifier extends StateNotifier<VoiceOverlayState> {
  VoiceOverlayNotifier() : super(const VoiceOverlayState());

  void open() => state = state.copyWith(
        isVisible: true,
        voiceState: VoiceChatState.listening,
      );

  void close() => state = state.copyWith(
        isVisible: false,
        voiceState: VoiceChatState.idle,
        amplitude: 0.0,
      );

  void startListening() =>
      state = state.copyWith(voiceState: VoiceChatState.listening);

  void startSpeaking() =>
      state = state.copyWith(voiceState: VoiceChatState.speaking);

  void setIdle() =>
      state = state.copyWith(voiceState: VoiceChatState.idle, amplitude: 0.0);

  /// Call this from your STT onSoundLevelChange callback.
  /// [raw] is the dB value typically –2 to 10; normalise it here.
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
//  CUSTOM PAINTER  – smooth multi-layer sine
// ─────────────────────────────────────────────

class SineWavePainter extends CustomPainter {
  final double phase;      // driven by AnimationController (0 → 2π)
  final double amplitude;  // 0.0 – 1.0
  final Color color;
  final VoiceChatState voiceState;

  SineWavePainter({
    required this.phase,
    required this.amplitude,
    required this.color,
    required this.voiceState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // When idle draw a flat dim line and return
    if (voiceState == VoiceChatState.idle) {
      final p = Paint()
        ..color = color.withOpacity(0.18)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, cy), Offset(size.width, cy), p);
      return;
    }

    // 3 stacked sine layers with slightly different freq / opacity
    final layers = [
      _WaveLayer(freqMult: 1.0,  ampMult: 1.0,   opacity: 0.85, strokeWidth: 2.5, phaseOffset: 0),
      _WaveLayer(freqMult: 1.4,  ampMult: 0.55,  opacity: 0.45, strokeWidth: 1.8, phaseOffset: math.pi * 0.6),
      _WaveLayer(freqMult: 0.7,  ampMult: 0.35,  opacity: 0.25, strokeWidth: 1.2, phaseOffset: math.pi * 1.2),
    ];

    for (final layer in layers) {
      _drawWave(canvas, size, cx, cy, layer);
    }
  }

  void _drawWave(Canvas canvas, Size size, double cx, double cy, _WaveLayer layer) {
    // Base amplitude grows with voice amplitude + a gentle idle pulse
    final baseAmp = (40 + amplitude * 90) * layer.ampMult;

    final paint = Paint()
      ..color = color.withOpacity(layer.opacity)
      ..strokeWidth = layer.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Soft glow pass
    final glowPaint = Paint()
      ..color = color.withOpacity(layer.opacity * 0.3)
      ..strokeWidth = layer.strokeWidth * 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final path = Path();
    final glowPath = Path();
    const steps = 200;

    for (int i = 0; i <= steps; i++) {
      final x = (i / steps) * size.width;
      // Envelope: fade wave to flat at edges (window function)
      final t = i / steps;
      final envelope = math.sin(t * math.pi);  // 0 → 1 → 0

      final y = cy +
          baseAmp *
              envelope *
              math.sin(layer.freqMult * 2 * math.pi * t * 2.5 +
                  phase +
                  layer.phaseOffset);

      if (i == 0) {
        path.moveTo(x, y);
        glowPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        glowPath.lineTo(x, y);
      }
    }

    canvas.drawPath(glowPath, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SineWavePainter old) =>
      old.phase != phase ||
      old.amplitude != amplitude ||
      old.voiceState != voiceState ||
      old.color != color;
}

class _WaveLayer {
  final double freqMult;
  final double ampMult;
  final double opacity;
  final double strokeWidth;
  final double phaseOffset;
  const _WaveLayer({
    required this.freqMult,
    required this.ampMult,
    required this.opacity,
    required this.strokeWidth,
    required this.phaseOffset,
  });
}

// ─────────────────────────────────────────────
//  ANIMATED WAVE WIDGET
// ─────────────────────────────────────────────

class AnimatedSineWave extends StatefulWidget {
  final double amplitude;
  final Color color;
  final VoiceChatState voiceState;
  final double height;

  const AnimatedSineWave({
    super.key,
    required this.amplitude,
    required this.color,
    required this.voiceState,
    this.height = 120,
  });

  @override
  State<AnimatedSineWave> createState() => _AnimatedSineWaveState();
}

class _AnimatedSineWaveState extends State<AnimatedSineWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        size: Size(double.infinity, widget.height),
        painter: SineWavePainter(
          phase: _controller.value * 2 * math.pi,
          amplitude: widget.amplitude,
          color: widget.color,
          voiceState: widget.voiceState,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FULL-SCREEN OVERLAY
// ─────────────────────────────────────────────

class VoiceChatOverlay extends ConsumerWidget {
  const VoiceChatOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayState = ref.watch(voiceOverlayProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: overlayState.isVisible
          ? _VoiceOverlayContent(key: const ValueKey('voice-overlay'))
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }
}

class _VoiceOverlayContent extends ConsumerWidget {
  const _VoiceOverlayContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceOverlayProvider);
    final notifier = ref.read(voiceOverlayProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Wave colour: purple when listening, white when speaking
    final waveColor = state.voiceState == VoiceChatState.listening
        ? AppColors.accent
        : AppColors.light;

    final statusLabel = switch (state.voiceState) {
      VoiceChatState.listening => 'Listening…',
      VoiceChatState.speaking  => 'Speaking…',
      VoiceChatState.idle      => 'Tap mic to speak',
    };

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          // subtle radial glow behind wave
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              (state.voiceState == VoiceChatState.listening
                      ? AppColors.accent
                      : AppColors.primary)
                  .withOpacity(isDark ? 0.12 : 0.06),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
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
                        // TODO: stop STT / TTS here before closing
                        notifier.close();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.canvasColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: theme.hintColor,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const Spacer(),

              // ── wave ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSineWave(
                  amplitude: state.amplitude,
                  color: waveColor,
                  voiceState: state.voiceState,
                  height: 130,
                ),
              ),

              const SizedBox(height: 40),

              // ── status label ────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  statusLabel,
                  key: ValueKey(statusLabel),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: waveColor.withOpacity(0.7),
                    letterSpacing: 0.8,
                  ),
                ),
              ).animate().fadeIn(duration: 250.ms),

              const Spacer(),

              // ── mic button ──────────────────────────────
              _MicButton(
                voiceState: state.voiceState,
                onTap: () {
                  if (state.voiceState == VoiceChatState.listening) {
                    // TODO: call speechToText.stop() here
                    notifier.setIdle();
                  } else {
                    // TODO: call speechToText.listen(...) here
                    notifier.startListening();
                  }
                },
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

              const SizedBox(height: 60),
            ],
          ),
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
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    if (widget.voiceState == VoiceChatState.listening) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.animateTo(0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isListening = widget.voiceState == VoiceChatState.listening;
    final isSpeaking  = widget.voiceState == VoiceChatState.speaking;

    final bgColor = isListening
        ? AppColors.accent
        : isSpeaking
            ? Colors.white12
            : theme.canvasColor;

    final iconColor = isListening ? Colors.white : theme.hintColor;

    return GestureDetector(
      onTap: isSpeaking ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // pulse ring
              if (isListening)
                Transform.scale(
                  scale: _pulse.value,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.35),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              // button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  boxShadow: isListening
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.45),
                            blurRadius: 24,
                            spreadRadius: 4,
                          )
                        ]
                      : [],
                ),
                child: Icon(
                  isSpeaking ? Icons.volume_up_outlined : Icons.mic,
                  color: iconColor,
                  size: 28,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}