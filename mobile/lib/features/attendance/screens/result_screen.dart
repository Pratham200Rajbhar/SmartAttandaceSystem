import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/core/attendance_utils.dart';
import 'package:smart_attendance_app/core/attendance_constants.dart';
import 'package:smart_attendance_app/data/repositories/attendance_repository.dart';
import 'package:smart_attendance_app/features/attendance/providers/attendance_provider.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnim = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vState = ref.watch(attendanceVerificationProvider);
    final result = vState.result;

    _ResultConfig config;
    if (vState.isError) {
      config = _ResultConfig.error(vState.errorMessage);
    } else if (result is OfflineQueued) {
      config = _ResultConfig.offline();
    } else if (result is OnlineResult) {
      final att = result.result;
      if (att.isPresent) {
        HapticFeedback.lightImpact();
        config = _ResultConfig.present(att);
      } else {
        HapticFeedback.lightImpact();
        config = _ResultConfig.flagged(att);
      }
    } else {
      config = _ResultConfig.processing();
    }

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _entryController,
                    builder: (context, child) => FadeTransition(
                      opacity: _fadeAnim,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnim.value),
                        child: child,
                      ),
                    ),
                    child: _buildContent(context, config, result, vState),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    _ResultConfig config,
    AttendanceSubmitResult? result,
    AttendanceVerificationState vState,
  ) {
    return Column(
      children: [
        const Spacer(flex: 2),
        // Hero icon
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) => Transform.scale(
            scale: _pulseAnim.value,
            child: child,
          ),
          child: AnimatedBuilder(
            animation: _scaleAnim,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
            child: _ResultHeroIcon(config: config),
          ),
        ),
        const SizedBox(height: 28),
        // Title
        Text(
          config.title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: SasColors.textPrimary,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        // Subtitle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: config.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: config.color.withValues(alpha: 0.2)),
          ),
          child: Text(
            config.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: config.color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
        const Spacer(flex: 1),
        // Score card
        if (config.scores != null) _ScoreCard(scores: config.scores!),
        const Spacer(flex: 2),
        // Actions
        _buildActions(context, result, vState),
      ],
    );
  }

  Widget _buildActions(
    BuildContext context,
    AttendanceSubmitResult? result,
    AttendanceVerificationState vState,
  ) {
    final isFlagged = result is OnlineResult && result.result.isFlagged;

    return Column(
      children: [
        if (isFlagged) ...[
          GlassButton(
            label: 'View Flagged Record',
            isExpanded: true,
            icon: Icons.info_outline_rounded,
            onPressed: () {
              ref.read(attendanceVerificationProvider.notifier).reset();
              context.go('/attendance');
            },
          ),
          const SizedBox(height: 10),
        ],
        GlassButton(
          label: 'Back to Dashboard',
          isExpanded: true,
          variant: isFlagged ? GlassButtonVariant.ghost : GlassButtonVariant.primary,
          icon: Icons.home_rounded,
          onPressed: () {
            ref.read(attendanceVerificationProvider.notifier).reset();
            context.go('/home');
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result Config
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreData {
  final double overall;
  final double face;
  final double liveness;
  final double background;
  const _ScoreData({
    required this.overall,
    required this.face,
    required this.liveness,
    required this.background,
  });
}

class _ResultConfig {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final _ScoreData? scores;

  const _ResultConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.scores,
  });

  factory _ResultConfig.error(String? message) => _ResultConfig(
        icon: Icons.error_outline_rounded,
        color: SasColors.danger,
        title: 'Submission Failed',
        subtitle: message ?? 'Something went wrong. Please try again.',
      );

  factory _ResultConfig.offline() => _ResultConfig(
        icon: Icons.cloud_sync_rounded,
        color: SasColors.info,
        title: 'Saved Offline',
        subtitle: 'Do not close the app. We\'ll sync when you reconnect.',
      );

  factory _ResultConfig.present(dynamic att) => _ResultConfig(
        icon: Icons.check_circle_rounded,
        color: SasColors.success,
        title: 'Verified!',
        subtitle: 'You are marked Present.',
        scores: _ScoreData(
          overall: att.finalAiScore,
          face: att.faceScore,
          liveness: att.livenessScore,
          background: att.backgroundScore,
        ),
      );

  factory _ResultConfig.flagged(dynamic att) => _ResultConfig(
        icon: Icons.warning_amber_rounded,
        color: SasColors.warning,
        title: 'Attempt Flagged',
        subtitle: 'Your teacher will review this submission.',
        scores: _ScoreData(
          overall: att.finalAiScore,
          face: att.faceScore,
          liveness: att.livenessScore,
          background: att.backgroundScore,
        ),
      );

  factory _ResultConfig.processing() => _ResultConfig(
        icon: Icons.hourglass_empty_rounded,
        color: SasColors.textMuted,
        title: 'Processing…',
        subtitle: 'Please wait',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Icon
// ─────────────────────────────────────────────────────────────────────────────

class _ResultHeroIcon extends StatelessWidget {
  final _ResultConfig config;
  const _ResultHeroIcon({required this.config});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                config.color.withValues(alpha: 0.15),
                config.color.withValues(alpha: 0.04),
                Colors.transparent,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
        // Inner circle
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                config.color.withValues(alpha: 0.2),
                config.color.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: config.color.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: config.color.withValues(alpha: 0.3),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(config.icon, size: 48, color: config.color),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Score Card
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreCard extends StatefulWidget {
  final _ScoreData scores;
  const _ScoreCard({required this.scores});

  @override
  State<_ScoreCard> createState() => _ScoreCardState();
}

class _ScoreCardState extends State<_ScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overallColor = scoreColor(widget.scores.overall);

    return GlassCard(
      borderColor: overallColor.withValues(alpha: 0.25),
      child: Column(
        children: [
          // Overall score ring
          Row(
            children: [
              _AnimatedScoreRing(
                score: widget.scores.overall,
                color: overallColor,
                animation: _progressAnim,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall AI Score',
                      style: TextStyle(
                        color: SasColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedBuilder(
                      animation: _progressAnim,
                      builder: (context, _) => Text(
                        '${(widget.scores.overall * 100 * _progressAnim.value).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: overallColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Text(
                      _overallLabel(widget.scores.overall),
                      style: TextStyle(
                        fontSize: 12,
                        color: overallColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  SasColors.glassBorder,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Sub-scores
          _SubScoreRow(
            label: 'Face Match',
            icon: Icons.face_rounded,
            score: widget.scores.face,
            animation: _progressAnim,
            hint: _faceHint(widget.scores.face),
          ),
          const SizedBox(height: 12),
          _SubScoreRow(
            label: 'Liveness',
            icon: Icons.visibility_rounded,
            score: widget.scores.liveness,
            animation: _progressAnim,
            hint: _livenessHint(widget.scores.liveness),
          ),
          const SizedBox(height: 12),
          _SubScoreRow(
            label: 'Background',
            icon: Icons.location_city_rounded,
            score: widget.scores.background,
            animation: _progressAnim,
            hint: _backgroundHint(widget.scores.background),
          ),
        ],
      ),
    );
  }

  String _overallLabel(double score) {
    if (score >= 0.85) return 'Excellent verification';
    if (score >= 0.7) return 'Good verification';
    if (score >= 0.5) return 'Marginal — flagged for review';
    return 'Low confidence';
  }

  String _faceHint(double score) {
    if (score >= 0.85) return 'Strong match';
    if (score >= kGoodScoreThreshold) return 'Good match';
    if (score >= 0.5) return 'Weak match';
    return 'Poor — try better lighting';
  }

  String _livenessHint(double score) {
    if (score >= 0.8) return 'Confirmed live';
    if (score >= 0.6) return 'Likely live';
    return 'Try better lighting';
  }

  String _backgroundHint(double score) {
    if (score >= kGoodScoreThreshold) return 'Classroom verified';
    return 'Unfamiliar background';
  }
}

class _AnimatedScoreRing extends StatelessWidget {
  final double score;
  final Color color;
  final Animation<double> animation;

  const _AnimatedScoreRing({
    required this.score,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => CustomPaint(
          painter: _RingPainter(
            progress: score * animation.value,
            color: color,
            trackColor: SasColors.glassBorder,
          ),
          child: Center(
            child: Icon(
              Icons.verified_rounded,
              color: color,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    final startAngle = -math.pi / 2;
    final fullSweep = 2 * math.pi;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + fullSweep * progress.clamp(0.0, 1.0),
        colors: [color.withValues(alpha: 0.6), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _SubScoreRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double score;
  final Animation<double> animation;
  final String hint;

  const _SubScoreRow({
    required this.label,
    required this.icon,
    required this.score,
    required this.animation,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(score);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: SasColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (score * animation.value).clamp(0.0, 1.0),
                backgroundColor: SasColors.glassBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) => Text(
            '${(score * 100 * animation.value).toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
