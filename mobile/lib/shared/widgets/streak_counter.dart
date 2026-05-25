
import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';

class StreakCounter extends StatelessWidget {
  final int currentStreak;
  final int highestStreak;
  final bool isCompact;

  const StreakCounter({
    super.key,
    required this.currentStreak,
    required this.highestStreak,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  Widget _buildCompactView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SasColors.accentEmerald.withValues(alpha: 0.2),
            SasColors.accentTeal.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SasColors.accentEmerald.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '$currentStreak',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: SasColors.accentEmerald,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'day streak',
            style: TextStyle(
              fontSize: 12,
              color: SasColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SasColors.accentEmerald.withValues(alpha: 0.2),
            SasColors.accentTeal.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SasColors.accentEmerald.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SasColors.accentEmerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance Streak',
                      style: TextStyle(
                        fontSize: 14,
                        color: SasColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$currentStreak',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: SasColors.accentEmerald,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentStreak == 1 ? 'day' : 'days',
                          style: const TextStyle(
                            fontSize: 16,
                            color: SasColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (highestStreak > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: SasColors.glassBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      size: 16, color: SasColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    'Best: $highestStreak ${highestStreak == 1 ? 'day' : 'days'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: SasColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (currentStreak == 0) ...[
            const SizedBox(height: 12),
            const Text(
              'Start your streak by attending classes!',
              style: TextStyle(
                fontSize: 12,
                color: SasColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
