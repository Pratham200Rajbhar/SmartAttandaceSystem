import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

/// Quick action grid for leave management on the home screen.
class LeaveQuickActions extends StatelessWidget {
  const LeaveQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: SasSpacing.xs),
        Row(
          children: [
            const Icon(
              Icons.event_note_rounded,
              color: SasColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: SasSpacing.sm),
            const Text(
              'Leave Management',
              style: TextStyle(
                color: SasColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: SasSpacing.sm),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                onTap: () => context.push('/leave/request'),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(SasSpacing.md),
                      decoration: BoxDecoration(
                        color:
                            SasColors.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: SasRadius.mdAll,
                      ),
                      child: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: SasColors.accentEmerald,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: SasSpacing.sm),
                    const Text(
                      'Request Leave',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Submit new request',
                      style: TextStyle(
                        color: SasColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: SasSpacing.sm),
            Expanded(
              child: GlassCard(
                onTap: () => context.push('/leave/history'),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(SasSpacing.md),
                      decoration: BoxDecoration(
                        color: SasColors.info.withValues(alpha: 0.15),
                        borderRadius: SasRadius.mdAll,
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: SasColors.info,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: SasSpacing.sm),
                    const Text(
                      'Leave History',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'View all requests',
                      style: TextStyle(
                        color: SasColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
