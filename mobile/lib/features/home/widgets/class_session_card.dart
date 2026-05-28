import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/features/home/providers/session_provider.dart';
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
            ? (widget.isMarked
                ? SasColors.success.withValues(alpha: 0.25)
                : SasColors.accentEmerald.withValues(alpha: 0.45))
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
                        ? (widget.isMarked
                            ? SasColors.success.withValues(alpha: 0.08)
                            : SasColors.accentEmerald.withValues(alpha: 0.12))
                        : SasColors.glassBg,
                    borderRadius: SasRadius.mdAll,
                    border: Border.all(
                      color: widget.session.isActive
                          ? (widget.isMarked
                              ? SasColors.success.withValues(alpha: 0.15)
                              : SasColors.accentEmerald.withValues(alpha: 0.25))
                          : SasColors.glassBorder,
                    ),
                  ),
                  child: Icon(
                    widget.isMarked
                        ? Icons.check_circle_outline_rounded
                        : Icons.school_rounded,
                    size: 20,
                    color: widget.session.isActive
                        ? (widget.isMarked
                            ? SasColors.success
                            : SasColors.accentEmerald)
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _PulsingDot(),
                        const SizedBox(width: 6),
                        const StatusChip(
                          label: 'LIVE',
                          color: SasColors.accentEmerald,
                        ),
                      ],
                    ),
                ],
              ],
            ),

            // Countdown timer pill
            if (widget.session.isActive &&
                _remaining != null &&
                !_isWindowClosed &&
                !widget.isMarked) ...[
              Container(
                margin: const EdgeInsets.only(top: SasSpacing.md),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (_remaining!.inMinutes < 2
                          ? SasColors.warning
                          : SasColors.accentEmerald)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_remaining!.inMinutes < 2
                            ? SasColors.warning
                            : SasColors.accentEmerald)
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: _remaining!.inMinutes < 2
                          ? SasColors.warning
                          : SasColors.accentEmerald,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_remaining!.inMinutes}:${(_remaining!.inSeconds % 60).toString().padLeft(2, '0')} remaining',
                      style: TextStyle(
                        color: _remaining!.inMinutes < 2
                            ? SasColors.warning
                            : SasColors.accentEmerald,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Attendance Recorded Success Banner
            if (widget.isMarked) ...[
              const SizedBox(height: SasSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: SasColors.success.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: SasColors.success.withValues(alpha: 0.15),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: SasColors.success,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Attendance recorded successfully',
                      style: TextStyle(
                        color: SasColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Mark attendance CTA
            if (_canMark) ...[
              const SizedBox(height: SasSpacing.md),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/verify/${widget.session.sessionId}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          SasColors.accentEmerald,
                          SasColors.accentTeal,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: SasColors.accentEmerald.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fingerprint_rounded,
                          color: Colors.black87,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Mark Attendance',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
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
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SasColors.accentEmerald.withValues(alpha: 0.3 + (_controller.value * 0.7)),
            boxShadow: [
              BoxShadow(
                color: SasColors.accentEmerald.withValues(alpha: _controller.value * 0.5),
                blurRadius: 4,
                offset: Offset.zero,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
