import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/domain/models/leaderboard.dart';
import 'package:smart_attendance_app/features/analytics/providers/leaderboard_provider.dart';
import 'package:smart_attendance_app/features/auth/providers/auth_provider.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_app_bar.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaderboardProvider);
    final currentStudentId = ref.watch(authProvider).user?.studentProfile?.id;

    return Scaffold(
      appBar: const GlassAppBar(
        title: 'Leaderboard',
        showBack: true,
      ),
      body: AnimatedBackground(
        child: RefreshIndicator(
          color: SasColors.accentEmerald,
          backgroundColor: SasColors.bgSurface,
          onRefresh: () => ref.read(leaderboardProvider.notifier).fetch(),
          child: _buildBody(context, state, currentStudentId),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LeaderboardState state,
    String? currentStudentId,
  ) {
    if (state.isLoading && state.data == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: SasColors.accentEmerald,
        ),
      );
    }

    if (state.errorMessage != null && state.data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: SasColors.danger,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                style: const TextStyle(
                  color: SasColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final response = state.data;
    if (response == null || response.leaderboard.isEmpty) {
      return const Center(
        child: Text(
          'No leaderboard data available.',
          style: TextStyle(color: SasColors.textMuted),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildUserSummaryCard(response),
        const SizedBox(height: 24),
        const Text(
          'TOP PERFORMERS',
          style: TextStyle(
            color: SasColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        ...response.leaderboard.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isCurrentUser = item.studentId == currentStudentId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildLeaderboardItem(index + 1, item, isCurrentUser),
          );
        }),
      ],
    );
  }

  Widget _buildUserSummaryCard(LeaderboardResponse response) {
    final rankText = response.userRank != null ? '#${response.userRank}' : 'N/A';

    return GlassCard(
      borderColor: SasColors.accentAmber.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text(
                'YOUR RANK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SasColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                rankText,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: SasColors.accentAmber,
                ),
              ),
            ],
          ),
          Container(
            height: 40,
            width: 1,
            color: SasColors.glassBorder,
          ),
          Column(
            children: [
              const Text(
                'TOTAL POINTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SasColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${response.userPoints}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: SasColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(
    int rank,
    LeaderboardEntry entry,
    bool isCurrentUser,
  ) {
    Color itemBorderColor = SasColors.glassBorder;
    if (isCurrentUser) {
      itemBorderColor = SasColors.accentEmerald.withValues(alpha: 0.4);
    } else if (rank == 1) {
      itemBorderColor = SasColors.accentAmber.withValues(alpha: 0.3);
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderColor: itemBorderColor,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: _buildRankBadge(rank),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: TextStyle(
                          fontWeight:
                              isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 14,
                          color: isCurrentUser
                              ? SasColors.success
                              : SasColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: SasColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: SasColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (entry.currentStreak > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: SasColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.currentStreak} streak',
                        style: const TextStyle(
                          fontSize: 12,
                          color: SasColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${entry.points} pts',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: rank == 1 ? SasColors.accentAmber : SasColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return const Icon(
        Icons.emoji_events_rounded,
        color: SasColors.accentAmber,
        size: 22,
      );
    } else if (rank == 2) {
      return const Icon(
        Icons.emoji_events_rounded,
        color: Color(0xFF94A3B8),
        size: 20,
      );
    } else if (rank == 3) {
      return const Icon(
        Icons.emoji_events_rounded,
        color: Color(0xFFD97706),
        size: 20,
      );
    }

    return Text(
      '#$rank',
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: SasColors.textMuted,
      ),
    );
  }
}
