// Result screen — displays outcome with contextual score explanations.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/data/repositories/attendance_repository.dart';
import 'package:smart_attendance_app/features/attendance/providers/attendance_provider.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vState = ref.watch(attendanceVerificationProvider);
    final result = vState.result;

    _ResultDisplay display;
    if (vState.isError) {
      display = _ResultDisplay(
        icon: Icons.error_outline_rounded,
        iconColor: SasColors.danger,
        glowColor: SasColors.danger,
        title: 'Submission Failed',
        subtitle: vState.errorMessage ?? 'Something went wrong',
      );
    } else if (result is OfflineQueued) {
      display = _ResultDisplay(
        icon: Icons.cloud_sync_rounded,
        iconColor: SasColors.info,
        glowColor: SasColors.info,
        title: 'Saved Offline',
        subtitle: 'Do not close the app. We will sync when you connect to Wi-Fi.',
      );
    } else if (result is OnlineResult) {
      final att = result.result;
      if (att.isPresent) {
        HapticFeedback.lightImpact();
        display = _ResultDisplay(
          icon: Icons.check_circle_rounded,
          iconColor: SasColors.success,
          glowColor: SasColors.success,
          title: 'Verified!',
          subtitle: 'You are marked Present.',
          score: att.finalAiScore,
          faceScore: att.faceScore,
          livenessScore: att.livenessScore,
          backgroundScore: att.backgroundScore,
        );
      } else {
        HapticFeedback.lightImpact();
        display = _ResultDisplay(
          icon: Icons.warning_amber_rounded,
          iconColor: SasColors.warning,
          glowColor: SasColors.warning,
          title: 'Attempt Flagged',
          subtitle: 'Your teacher will review this submission.',
          score: att.finalAiScore,
          faceScore: att.faceScore,
          livenessScore: att.livenessScore,
          backgroundScore: att.backgroundScore,
        );
      }
    } else {
      display = _ResultDisplay(
        icon: Icons.hourglass_empty_rounded,
        iconColor: SasColors.textMuted,
        glowColor: SasColors.textMuted,
        title: 'Processing…',
        subtitle: 'Please wait',
      );
    }

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Result icon with glow
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: display.glowColor.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(color: display.glowColor.withValues(alpha: 0.25), blurRadius: 40),
                    ],
                  ),
                  child: Icon(display.icon, size: 52, color: display.iconColor),
                ),
                const SizedBox(height: 24),
                Text(display.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(display.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: SasColors.textSecondary, fontSize: 15)),

                if (display.score != null) ...[
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Overall AI Score: ',
                                style: TextStyle(color: SasColors.textMuted, fontSize: 14)),
                            Text('${(display.score! * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: display.iconColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                )),
                          ],
                        ),
                        if (display.faceScore != null) ...[
                          const SizedBox(height: 12),
                          const Divider(color: SasColors.glassBorder),
                          const SizedBox(height: 12),
                          _buildSubScore('Face', display.faceScore!),
                          const SizedBox(height: 8),
                          _buildSubScore('Liveness', display.livenessScore!),
                          const SizedBox(height: 8),
                          _buildSubScore('Background', display.backgroundScore!),
                        ],
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Primary action: view attendance record (for flagged)
                if (result is OnlineResult && !result.result.isPresent) ...[
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
                  variant: result is OnlineResult && !result.result.isPresent
                      ? GlassButtonVariant.ghost
                      : GlassButtonVariant.primary,
                  icon: Icons.home_rounded,
                  onPressed: () {
                    ref.read(attendanceVerificationProvider.notifier).reset();
                    context.go('/home');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubScore(String label, double score) {
    final color = score >= 0.7 ? SasColors.success : (score >= 0.4 ? SasColors.warning : SasColors.danger);
    final hint = _scoreHint(label, score);
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(color: SasColors.textMuted, fontSize: 12)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score.clamp(0.0, 1.0),
              backgroundColor: SasColors.glassBg,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text('${(score * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        Expanded(
          child: Text(hint,
              style: const TextStyle(color: SasColors.textMuted, fontSize: 10),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  String _scoreHint(String label, double score) {
    if (label == 'Face') {
      if (score >= 0.85) return 'Strong match';
      if (score >= 0.7) return 'Good match';
      if (score >= 0.5) return 'Weak match';
      return 'Poor match — try better lighting';
    }
    if (label == 'Liveness') {
      if (score >= 0.8) return 'Confirmed live';
      if (score >= 0.6) return 'Likely live';
      return 'Try better lighting';
    }
    if (label == 'Background') {
      if (score >= 0.7) return 'Classroom verified';
      return 'Unfamiliar background';
    }
    return '';
  }
}

class _ResultDisplay {
  final IconData icon;
  final Color iconColor;
  final Color glowColor;
  final String title;
  final String subtitle;
  final double? score;
  final double? faceScore;
  final double? livenessScore;
  final double? backgroundScore;

  const _ResultDisplay({
    required this.icon,
    required this.iconColor,
    required this.glowColor,
    required this.title,
    required this.subtitle,
    this.score,
    this.faceScore,
    this.livenessScore,
    this.backgroundScore,
  });
}
