import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/features/home/providers/session_provider.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';
import 'package:smart_attendance_app/shared/widgets/status_chip.dart';

/// Card displaying a single class session with countdown timer and mark-attendance CTA.
class ClassSessionCard extends StatefulWidget {
  final ClassSession session;
  final bool isMarked;
  const ClassSessionCard({
    super.key,
    required this.session,
    required this.isMarked,
  });

  @override
  State<ClassSessionCard> createState() => _ClassSessionCardState();
}

class _ClassSessionCardState extends State<ClassSessionCard> {
  Timer? _countdownTimer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(ClassSessionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.session.sessionEndTime != oldWidget.session.sessionEndTime) {
      _countdownTimer?.cancel();
      _startCountdown();
    }
  }

  void _startCountdown() {
    final endTime = widget.session.sessionEndTime;
    if (endTime == null || !widget.session.isActive) return;

    _updateRemaining(endTime);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining(endTime);
    });
  }

  void _updateRemaining(DateTime endTime) {
    final diff = endTime.difference(DateTime.now());
    if (mounted) {
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    }
    if (diff.isNegative) {
      _countdownTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool get _isWindowClosed =>
      _remaining != null && _remaining == Duration.zero;

  bool get _canMark =>
      widget.session.isActive &&
      widget.session.sessionId != null &&
      !widget.isMarked &&
      !_isWindowClosed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SasSpacing.md),
      child: GlassCard(
        borderColor: widget.session.isActive
            ? SasColors.accentEmerald.withValues(alpha: 0.4)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.session.isActive
                        ? SasColors.accentEmerald.withValues(alpha: 0.15)
                        : SasColors.glassBg,
                    borderRadius: SasRadius.mdAll,
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    size: 20,
                    color: widget.session.isActive
                        ? SasColors.accentEmerald
                        : SasColors.textMuted,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session.className,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.session.subject,
                        style: const TextStyle(
                          color: SasColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        widget.session.teacherName,
                        style: const TextStyle(
                          color: SasColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.session.isActive) ...[
                  if (widget.isMarked)
                    const StatusChip(
                      label: 'SUBMITTED',
                      color: SasColors.success,
                    )
                  else if (_isWindowClosed)
                    const StatusChip(
                      label: 'CLOSED',
                      color: SasColors.danger,
                    )
                  else
                    const StatusChip(
                      label: 'LIVE',
                      color: SasColors.accentEmerald,
                    ),
                ],
              ],
            ),

            // Countdown timer
            if (widget.session.isActive &&
                _remaining != null &&
                !_isWindowClosed) ...[
              const SizedBox(height: SasSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: SasColors.textMuted,
                  ),
                  const SizedBox(width: SasSpacing.xs),
                  Text(
                    '${_remaining!.inMinutes}:${(_remaining!.inSeconds % 60).toString().padLeft(2, '0')} remaining',
                    style: TextStyle(
                      color: _remaining!.inMinutes < 2
                          ? SasColors.warning
                          : SasColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            // Mark attendance CTA
            if (_canMark) ...[
              const SizedBox(height: SasSpacing.lg),
              GlassButton(
                label: 'Mark Attendance',
                isExpanded: true,
                icon: Icons.fingerprint_rounded,
                onPressed: () =>
                    context.push('/verify/${widget.session.sessionId}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
