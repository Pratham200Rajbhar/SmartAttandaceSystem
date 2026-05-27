
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/core/attendance_utils.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/data/repositories/attendance_repository.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_app_bar.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class FlaggedDetailScreen extends ConsumerStatefulWidget {
  final AttendanceHistoryItem? item;
  final String? attendanceId;
  const FlaggedDetailScreen({super.key, this.item, this.attendanceId});

  @override
  ConsumerState<FlaggedDetailScreen> createState() =>
      _FlaggedDetailScreenState();
}

class _FlaggedDetailScreenState extends ConsumerState<FlaggedDetailScreen> {
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  bool _noteSubmitted = false;

  AttendanceHistoryItem? _item;
  bool _isLoadingItem = false;
  String? _errorLoadingItem;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _item = widget.item;
    } else if (widget.attendanceId != null) {
      _loadItem();
    }
  }

  Future<void> _loadItem() async {
    setState(() {
      _isLoadingItem = true;
      _errorLoadingItem = null;
    });
    try {
      final historyRes = await ref.read(attendanceRepositoryProvider).getHistory();
      final found = historyRes.history.firstWhere(
        (element) => element.attendanceId == widget.attendanceId,
      );
      if (mounted) {
        setState(() {
          _item = found;
          _isLoadingItem = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorLoadingItem = 'Failed to load details: $e';
          _isLoadingItem = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingItem) {
      return const Scaffold(
        appBar: GlassAppBar(title: 'Flagged Submission', showBack: true),
        body: AnimatedBackground(
          child: Center(
            child: CircularProgressIndicator(color: SasColors.accentEmerald),
          ),
        ),
      );
    }

    if (_item == null) {
      return Scaffold(
        appBar: const GlassAppBar(title: 'Flagged Submission', showBack: true),
        body: AnimatedBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorLoadingItem ?? 'Submission not found.',
                    style: const TextStyle(color: SasColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_errorLoadingItem != null)
                    ElevatedButton(
                      onPressed: _loadItem,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final item = _item!;
    final itemColor = statusColor(item.status);

    return Scaffold(
      appBar: const GlassAppBar(title: 'Flagged Submission', showBack: true),
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              
              GlassCard(
                borderColor: itemColor.withValues(alpha: 0.3),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: itemColor.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        isPresentOrApproved(item.status)
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        color: itemColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(item.className,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(item.subject,
                        style: const TextStyle(
                            color: SasColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: itemColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: itemColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(item.status,
                          style: TextStyle(
                              color: itemColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, MMMM d · h:mm a')
                          .format(item.markedAt),
                      style: const TextStyle(
                          color: SasColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (item.finalAiScore != null) ...[
                const Text(
                  'AI SCORE BREAKDOWN',
                  style: TextStyle(
                    color: SasColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ScoreBar(
                        label: 'Face Match',
                        score: item.faceScore ?? 0,
                        hint: item.faceScore != null && item.faceScore! < 0.7
                            ? 'Face similarity below threshold. Ensure good lighting and look directly at the camera.'
                            : 'Strong face match.',
                      ),
                      const SizedBox(height: 12),
                      _ScoreBar(
                        label: 'Liveness',
                        score: item.livenessScore ?? 0,
                        hint: item.livenessScore != null &&
                                item.livenessScore! < 0.7
                            ? 'Liveness check failed. Try better lighting, remove glasses, or avoid reflective surfaces.'
                            : 'Liveness confirmed.',
                      ),
                      const SizedBox(height: 12),
                      _ScoreBar(
                        label: 'Background',
                        score: item.backgroundScore ?? 0,
                        hint: item.backgroundScore != null &&
                                item.backgroundScore! < 0.7
                            ? 'Background not recognized as a learning environment. Try from your usual classroom position.'
                            : 'Background verified.',
                      ),
                      const Divider(
                          color: SasColors.glassBorder, height: 24),
                      _ScoreBar(
                        label: 'Final Score',
                        score: item.finalAiScore ?? 0,
                        isHighlighted: true,
                        hint: item.finalAiScore != null &&
                                item.finalAiScore! < 0.6
                            ? 'Overall score below the passing threshold.'
                            : 'Score is above threshold.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _WhySection(),

              const SizedBox(height: 16),

              if (item.teacherNote != null) ...[
                const Text(
                  'TEACHER REVIEW NOTE',
                  style: TextStyle(
                    color: SasColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                GlassCard(
                  borderColor: SasColors.info.withValues(alpha: 0.3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person_rounded,
                          color: SasColors.info, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.teacherNote!,
                          style: const TextStyle(
                              color: SasColors.textSecondary,
                              fontSize: 13,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (item.status == 'Flagged') ...[
                const Text(
                  'ADD A NOTE FOR YOUR TEACHER',
                  style: TextStyle(
                    color: SasColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Or add a quick note to explain the circumstances.',
                        style: TextStyle(
                            color: SasColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      if (_noteSubmitted)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SasColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    SasColors.success.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: SasColors.success, size: 18),
                              SizedBox(width: 8),
                              Text('Note submitted successfully.',
                                  style: TextStyle(
                                      color: SasColors.success,
                                      fontSize: 13)),
                            ],
                          ),
                        )
                      else ...[
                        TextField(
                          controller: _noteController,
                          maxLines: 4,
                          maxLength: 500,
                          style: const TextStyle(
                              color: SasColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText:
                                'e.g., I was sitting at the back, lighting was dim…',
                            hintStyle: const TextStyle(
                                color: SasColors.textMuted, fontSize: 13),
                            filled: true,
                            fillColor: SasColors.glassBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: SasColors.glassBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: SasColors.glassBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: SasColors.glassBorderHover),
                            ),
                            counterStyle: const TextStyle(
                                color: SasColors.textMuted, fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassButton(
                          label: 'Submit Note',
                          isExpanded: true,
                          isLoading: _isSubmitting,
                          icon: Icons.send_rounded,
                          onPressed:
                              _isSubmitting ? null : _submitNote,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitNote() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a note before submitting.'),
          backgroundColor: SasColors.warning,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(studentApiProvider)
          .submitFlaggedNote(_item!.attendanceId, note);
      if (mounted) setState(() => _noteSubmitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit note: $e'),
            backgroundColor: SasColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final String hint;
  final bool isHighlighted;

  const _ScoreBar({
    required this.label,
    required this.score,
    required this.hint,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight:
                    isHighlighted ? FontWeight.w700 : FontWeight.w500,
                fontSize: isHighlighted ? 14 : 13,
                color: isHighlighted
                    ? SasColors.textPrimary
                    : SasColors.textSecondary,
              ),
            ),
            Text(
              '${(score * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: isHighlighted ? 16 : 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score.clamp(0.0, 1.0),
            backgroundColor: SasColors.glassBg,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: isHighlighted ? 8 : 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: const TextStyle(
              color: SasColors.textMuted, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }
}

class _WhySection extends StatefulWidget {
  @override
  State<_WhySection> createState() => _WhySectionState();
}

class _WhySectionState extends State<_WhySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Text(
            'Why might this happen?',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: SasColors.textPrimary),
          ),
          trailing: Icon(
            _expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: SasColors.textMuted,
          ),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          children: const [
            _ReasonTile(
              icon: Icons.wb_sunny_outlined,
              title: 'Poor lighting',
              desc:
                  'Dim or harsh lighting reduces face recognition accuracy. Try near a window or under good indoor lighting.',
            ),
            SizedBox(height: 8),
            _ReasonTile(
              icon: Icons.face_retouching_off_rounded,
              title: 'Face partially covered',
              desc:
                  'Masks, scarves, or hands near the face reduce the match score. Ensure your full face is visible.',
            ),
            SizedBox(height: 8),
            _ReasonTile(
              icon: Icons.remove_red_eye_outlined,
              title: 'Glasses glare',
              desc:
                  'Reflective glasses can confuse the liveness check. Try removing glasses or adjusting the angle.',
            ),
            SizedBox(height: 8),
            _ReasonTile(
              icon: Icons.location_off_rounded,
              title: 'Unfamiliar background',
              desc:
                  'The background model was trained on classroom environments. Unusual backgrounds lower the score.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _ReasonTile(
      {required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: SasColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: SasColors.textSecondary)),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(
                      color: SasColors.textMuted,
                      fontSize: 12,
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}


