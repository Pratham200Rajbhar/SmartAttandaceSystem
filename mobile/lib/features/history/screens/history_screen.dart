
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/core/extensions.dart';
import 'package:smart_attendance_app/core/attendance_utils.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/features/history/providers/history_provider.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';
import 'package:smart_attendance_app/shared/widgets/legend_dot.dart';
import 'package:smart_attendance_app/shared/widgets/shimmer_placeholder.dart';
import 'package:smart_attendance_app/shared/widgets/status_chip.dart';
import 'package:smart_attendance_app/shared/widgets/stat_tile.dart';

enum _HistoryTab { calendar, list }
enum _ListFilter { all, present, absent, flagged }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _HistoryTab _tab = _HistoryTab.calendar;
  _ListFilter _filter = _ListFilter.all;
  String? _subjectFilter;
  DateTime _focusedMonth = DateTime.now();
  late DateTime _selectedDate;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    ref.read(historyProvider.notifier).fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hState = ref.watch(historyProvider);
    final pct = hState.data?.overallAttendancePercentage ?? 0;

    return AnimatedBackground(
      child: SafeArea(
        child: RefreshIndicator(
          color: SasColors.accentEmerald,
          backgroundColor: SasColors.bgSecondary,
          onRefresh: () => ref.read(historyProvider.notifier).fetch(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pctColor(pct).withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text('${pct.toStringAsFixed(0)}%',
                            style: TextStyle(
                                color: pctColor(pct),
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overall Attendance',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('Across all enrolled courses',
                            style: TextStyle(
                                color: SasColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(
                  color: SasColors.glassBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SasColors.glassBorder),
                ),
                child: Row(
                  children: [
                    _TabButton(
                      label: 'Calendar',
                      icon: Icons.calendar_month_rounded,
                      selected: _tab == _HistoryTab.calendar,
                      onTap: () => setState(() => _tab = _HistoryTab.calendar),
                    ),
                    _TabButton(
                      label: 'List',
                      icon: Icons.list_rounded,
                      selected: _tab == _HistoryTab.list,
                      onTap: () => setState(() => _tab = _HistoryTab.list),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (hState.errorMessage != null && hState.data == null)
                GlassCard(
                  borderColor: SasColors.danger.withValues(alpha: 0.3),
                  child: Column(children: [
                    const SizedBox(height: 12),
                    const Icon(Icons.cloud_off_rounded, size: 40, color: SasColors.danger),
                    const SizedBox(height: 12),
                    Text(hState.errorMessage!, textAlign: TextAlign.center,
                        style: const TextStyle(color: SasColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 16),
                    GlassButton(label: 'Retry', icon: Icons.refresh_rounded,
                        onPressed: () => ref.read(historyProvider.notifier).fetch()),
                    const SizedBox(height: 12),
                  ]),
                )
              else if (hState.isLoading && hState.data == null)
                const ShimmerCalendarPlaceholder()
              else if (_tab == _HistoryTab.calendar)
                _buildCalendarView(hState)
              else
                _buildListView(hState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView(HistoryState hState) {
    final grouped = hState.groupedByDate;
    
    final monthItems = (hState.data?.history ?? []).where((h) =>
        h.markedAt.year == _focusedMonth.year &&
        h.markedAt.month == _focusedMonth.month).toList();
    final mPresent = countPresentOrApproved(monthItems);
    final mAbsent = countAbsent(monthItems);
    final mFlagged = countFlagged(monthItems);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        if (hState.data != null && hState.data!.history.isNotEmpty)
          _PerSubjectBreakdown(history: hState.data!.history),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCalendarHeader(),
              const SizedBox(height: 12),
              _buildDayHeaders(),
              const SizedBox(height: 8),
              _buildCalendarGrid(grouped),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LegendDot(color: SasColors.success, label: 'Present'),
                  const SizedBox(width: 12),
                  LegendDot(color: SasColors.warning, label: 'Flagged'),
                  const SizedBox(width: 12),
                  LegendDot(color: SasColors.danger, label: 'Absent'),
                ],
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: SasColors.glassBg,
                  borderRadius: SasRadius.mdAll,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatTile(label: 'Present', value: '$mPresent', color: SasColors.success, variant: StatTileVariant.minimal),
                    StatTile(label: 'Absent', value: '$mAbsent', color: SasColors.danger, variant: StatTileVariant.minimal),
                    StatTile(label: 'Flagged', value: '$mFlagged', color: SasColors.warning, variant: StatTileVariant.minimal),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(_selectedDate.formattedDate,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                color: SasColors.textSecondary)),
        const SizedBox(height: 8),
        ..._buildDayItems(grouped[_selectedDate] ?? []),
      ],
    );
  }

  Widget _buildListView(HistoryState hState) {
    final all = hState.data?.history ?? [];
    
    final subjects = all.map((h) => h.subject).toSet().toList()..sort();

    var filtered = all.where((h) {
      if (_filter == _ListFilter.present) return h.status == 'Present' || h.status == 'Approved';
      if (_filter == _ListFilter.absent) return h.status == 'Absent';
      if (_filter == _ListFilter.flagged) return h.status == 'Flagged';
      return true;
    }).toList();

    if (_subjectFilter != null) {
      filtered = filtered.where((h) => h.subject == _subjectFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((h) =>
          h.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          h.className.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    filtered.sort((a, b) => b.markedAt.compareTo(a.markedAt));

    final total = all.length;
    final present = countPresentOrApproved(all);
    final absent = countAbsent(all);
    final flagged = countFlagged(all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        Row(
          children: [
            Expanded(child: StatTile(label: 'Total', value: '$total', color: SasColors.info, variant: StatTileVariant.pill)),
            const SizedBox(width: 6),
            Expanded(child: StatTile(label: 'Present', value: '$present', color: SasColors.success, variant: StatTileVariant.pill)),
            const SizedBox(width: 6),
            Expanded(child: StatTile(label: 'Absent', value: '$absent', color: SasColors.danger, variant: StatTileVariant.pill)),
            const SizedBox(width: 6),
            Expanded(child: StatTile(label: 'Flagged', value: '$flagged', color: SasColors.warning, variant: StatTileVariant.pill)),
          ],
        ),
        const SizedBox(height: 12),
        
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(color: SasColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by subject or class…',
            hintStyle: const TextStyle(color: SasColors.textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: SasColors.textMuted, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: SasColors.textMuted, size: 18),
                    onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                : null,
          ),
        ),
        const SizedBox(height: 10),
        
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._ListFilter.values.map((f) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: StatusChip(
                  label: f.name[0].toUpperCase() + f.name.substring(1),
                  color: SasColors.accentEmerald,
                  isSelected: _filter == f,
                  onTap: () => setState(() => _filter = f),
                  variant: StatusChipVariant.outlined,
                ),
              )),
              if (subjects.isNotEmpty) ...[
                const SizedBox(width: 4),
                const Text('|', style: TextStyle(color: SasColors.glassBorder)),
                const SizedBox(width: 4),
                ...subjects.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: StatusChip(
                    label: s.length > 12 ? '${s.substring(0, 12)}…' : s,
                    color: SasColors.accentTeal,
                    isSelected: _subjectFilter == s,
                    onTap: () => setState(() => _subjectFilter = _subjectFilter == s ? null : s),
                    variant: StatusChipVariant.outlined,
                  ),
                )),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          GlassCard(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No records match your filters.',
                    style: TextStyle(color: SasColors.textMuted, fontSize: 13)),
              ),
            ),
          )
        else
          ...filtered.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ListItemCard(item: item),
          )),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: SasColors.textSecondary),
          onPressed: () => setState(() {
            _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
          }),
        ),
        Text(DateFormat.yMMMM().format(_focusedMonth),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, color: SasColors.textSecondary),
          onPressed: () => setState(() {
            _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
          }),
        ),
      ],
    );
  }

  Widget _buildDayHeaders() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: days.map((d) => Expanded(
        child: Center(child: Text(d,
            style: const TextStyle(color: SasColors.textMuted, fontSize: 11,
                fontWeight: FontWeight.w600))),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid(Map<DateTime, List<AttendanceHistoryItem>> grouped) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday;
    final cells = <Widget>[];
    for (int i = 1; i < startWeekday; i++) { cells.add(const SizedBox()); }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final items = grouped[date];
      final isSelected = date.isSameDay(_selectedDate);
      final isToday = date.isSameDay(DateTime.now());
      Color? dotColor;
      if (items != null && items.isNotEmpty) {
        final statuses = items.map((i) => i.status).toSet();
        if (statuses.contains('Flagged')) {
          dotColor = SasColors.warning;
        } else if (statuses.every((s) => s == 'Present' || s == 'Approved')) {
          dotColor = SasColors.success;
        } else {
          dotColor = SasColors.danger;
        }
      }
      cells.add(GestureDetector(
        onTap: () => setState(() => _selectedDate = date),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? SasColors.accentEmerald.withValues(alpha: 0.15)
                : isToday ? SasColors.glassBgHover : null,
            border: isSelected ? Border.all(color: SasColors.accentEmerald.withValues(alpha: 0.5))
                : isToday ? Border.all(color: SasColors.glassBorderHover) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$day', style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? SasColors.accentEmerald : SasColors.textPrimary,
              )),
              if (dotColor != null)
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                ),
            ],
          ),
        ),
      ));
    }
    return GridView.count(
      crossAxisCount: 7, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.85, children: cells,
    );
  }

  List<Widget> _buildDayItems(List<AttendanceHistoryItem> items) {
    if (items.isEmpty) {
      return [GlassCard(child: const Center(child: Padding(
        padding: EdgeInsets.all(12),
        child: Text('No attendance records for this day.',
            style: TextStyle(color: SasColors.textMuted, fontSize: 13)),
      )))];
    }
    return items.map((item) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _HistoryItemCard(item: item),
    )).toList();
  }


}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? SasColors.accentEmerald.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? SasColors.accentEmerald : SasColors.textMuted),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: selected ? SasColors.accentEmerald : SasColors.textMuted,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// _FilterChip, _StatChip, _MonthStat, _LegendDot replaced by shared widgets:
// StatusChip, StatTile, LegendDot from shared/widgets/

class _ListItemCard extends StatelessWidget {
  final AttendanceHistoryItem item;
  const _ListItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(item.status);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: isFlagged(item.status)
          ? () => context.push('/flagged/${item.attendanceId}', extra: item)
          : null,
      child: Row(
        children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.subject, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(item.className, style: const TextStyle(color: SasColors.textMuted, fontSize: 11)),
                Text(DateFormat('MMM d · h:mm a').format(item.markedAt),
                    style: const TextStyle(color: SasColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          if (item.finalAiScore != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: SasColors.glassBg, borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${(item.finalAiScore! * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: SasColors.textMuted, fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(item.status, style: TextStyle(color: color, fontSize: 11,
                fontWeight: FontWeight.w700)),
          ),
          if (isFlagged(item.status)) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: SasColors.textMuted, size: 16),
          ],
        ],
      ),
    );
  }
}

class _HistoryItemCard extends StatefulWidget {
  final AttendanceHistoryItem item;
  const _HistoryItemCard({required this.item});
  @override
  State<_HistoryItemCard> createState() => _HistoryItemCardState();
}

class _HistoryItemCardState extends State<_HistoryItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasAiScores = item.finalAiScore != null;
    final itemStatusColor = statusColor(item.status);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: isFlagged(item.status)
          ? () => context.push('/flagged/${item.attendanceId}', extra: item)
          : (hasAiScores ? () => setState(() => _expanded = !_expanded) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: itemStatusColor)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.className, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(item.subject, style: const TextStyle(color: SasColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: itemStatusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: itemStatusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(item.status, style: TextStyle(color: itemStatusColor,
                        fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  Text(DateFormat.jm().format(item.markedAt),
                      style: const TextStyle(color: SasColors.textMuted, fontSize: 11)),
                ],
              ),
              if (hasAiScores && item.status != 'Flagged') ...[
                const SizedBox(width: 8),
                Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18, color: SasColors.textMuted),
              ],
              if (item.status == 'Flagged') ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 18, color: SasColors.textMuted),
              ],
            ],
          ),
          if (_expanded && hasAiScores) ...[
            const SizedBox(height: 12),
            const Divider(color: SasColors.glassBorder, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ScoreChip(label: 'Face', score: item.faceScore ?? 0),
                _ScoreChip(label: 'Liveness', score: item.livenessScore ?? 0),
                _ScoreChip(label: 'Background', score: item.backgroundScore ?? 0),
                _ScoreChip(label: 'Final', score: item.finalAiScore ?? 0),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final double score;
  const _ScoreChip({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(score);
    return Column(
      children: [
        Text(label, style: const TextStyle(color: SasColors.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text('${(score * 100).toStringAsFixed(0)}%',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}

class _PerSubjectBreakdown extends StatelessWidget {
  final List<AttendanceHistoryItem> history;
  const _PerSubjectBreakdown({required this.history});

  @override
  Widget build(BuildContext context) {
    final subjectStats = <String, _SubjectStat>{};
    for (final item in history) {
      final stat = subjectStats.putIfAbsent(item.classId,
          () => _SubjectStat(name: item.subject, className: item.className));
      stat.total++;
      if (item.status == 'Present' || item.status == 'Approved') stat.present++;
    }
    if (subjectStats.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Per-Subject Breakdown',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                color: SasColors.textSecondary)),
        const SizedBox(height: 8),
        ...subjectStats.values.map((stat) {
          final pct = stat.total > 0 ? (stat.present / stat.total * 100) : 0.0;
          final color = pct >= 75 ? SasColors.success : (pct >= 50 ? SasColors.warning : SasColors.danger);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stat.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(stat.className, style: const TextStyle(color: SasColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('${stat.present}/${stat.total}',
                      style: const TextStyle(color: SasColors.textMuted, fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text('${pct.toStringAsFixed(0)}%',
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SubjectStat {
  final String name;
  final String className;
  int total = 0;
  int present = 0;
  _SubjectStat({required this.name, required this.className});
}

// _ShimmerCalendar replaced by shared ShimmerCalendarPlaceholder
