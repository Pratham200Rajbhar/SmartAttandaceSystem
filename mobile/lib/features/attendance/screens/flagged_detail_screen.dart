
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_app_bar.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class FlaggedDetailScreen extends ConsumerStatefulWidget {
  final AttendanceHistoryItem item;
  const FlaggedDetailScreen({super.key, required this.item});

  @override
  ConsumerState<FlaggedDetailScreen> createState() =>
      _FlaggedDetailScreenState();
}

class _FlaggedDetailScreenState extends ConsumerState<FlaggedDetailScreen> {
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  bool _noteSubmitted = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final statusColor = item.status == 'Approved'
        ? SasColors.success
        : item.status == 'Flagged'
            ? SasColors.warning
            : SasColors.danger;

    return Scaffold(
      appBar: const GlassAppBar(title: 'Flagged Submission'),
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              
              GlassCard(
                borderColor: statusColor.withValues(alpha: 0.3),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        item.status == 'Approved'
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        color: statusColor,
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
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(item.status,
                          style: TextStyle(
                              color: statusColor,
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
                  'SUBMIT A DISPUTE',
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
                        'If you believe this flagged attendance is incorrect, you can submit a formal dispute with supporting evidence.',
                        style: TextStyle(
                            color: SasColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      GlassButton(
                        label: 'Submit Dispute',
                        isExpanded: true,
                        icon: Icons.gavel_rounded,
                        onPressed: () => _showDisputeBottomSheet(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
          .submitFlaggedNote(widget.item.attendanceId, note);
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

  void _showDisputeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DisputeBottomSheet(
        attendanceId: widget.item.attendanceId,
        className: widget.item.className,
        subject: widget.item.subject,
        onSuccess: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dispute submitted successfully. Your teacher will review it soon.'),
                backgroundColor: SasColors.success,
              ),
            );
          }
        },
      ),
    );
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
    final color = score >= 0.7
        ? SasColors.success
        : (score >= 0.4 ? SasColors.warning : SasColors.danger);

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

class _DisputeBottomSheet extends ConsumerStatefulWidget {
  final String attendanceId;
  final String className;
  final String subject;
  final VoidCallback onSuccess;

  const _DisputeBottomSheet({
    required this.attendanceId,
    required this.className,
    required this.subject,
    required this.onSuccess,
  });

  @override
  ConsumerState<_DisputeBottomSheet> createState() => _DisputeBottomSheetState();
}

class _DisputeBottomSheetState extends ConsumerState<_DisputeBottomSheet> {
  final _reasonController = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isSubmitting = false;
  String _selectedReason = 'GPS Inaccurate';

  final List<String> _reasonOptions = [
    'GPS Inaccurate',
    'Poor Lighting',
    'Camera Issue',
    'Network Problem',
    'System Error',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (_) {} 
  }

  Future<void> _submit() async {
    final note = _reasonController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter dispute details.'),
          backgroundColor: SasColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(studentApiProvider).submitDispute(
            attendanceId: widget.attendanceId,
            reason: '$_selectedReason: $note',
            proofImagePath: _selectedImage?.path,
          );
      if (mounted) {
        Navigator.pop(context); 
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit dispute: $e'),
            backgroundColor: SasColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: SasColors.glassBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: SasColors.glassBorder),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SasColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Submit Dispute',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: SasColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: SasColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Text(
                'Class: ${widget.className} (${widget.subject})',
                style: const TextStyle(
                  color: SasColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'DISPUTE REASON',
                style: TextStyle(
                  color: SasColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _reasonOptions.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedReason = reason),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? SasColors.warning.withValues(alpha: 0.2)
                            : SasColors.glassBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? SasColors.warning.withValues(alpha: 0.5)
                              : SasColors.glassBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        reason,
                        style: TextStyle(
                          color: isSelected
                              ? SasColors.warning
                              : SasColors.textSecondary,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'PROOF IMAGE (OPTIONAL)',
                style: TextStyle(
                  color: SasColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedImage != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickImage(ImageSource.gallery),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: SasColors.glassBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SasColors.glassBorder),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.photo_library_outlined,
                                  color: SasColors.textMuted, size: 24),
                              SizedBox(height: 6),
                              Text(
                                'Gallery',
                                style: TextStyle(
                                  color: SasColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickImage(ImageSource.camera),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: SasColors.glassBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SasColors.glassBorder),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  color: SasColors.textMuted, size: 24),
                              SizedBox(height: 6),
                              Text(
                                'Camera',
                                style: TextStyle(
                                  color: SasColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              
              const Text(
                'ADDITIONAL DETAILS *',
                style: TextStyle(
                  color: SasColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: 500,
                style: const TextStyle(color: SasColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      'Explain what happened and why you believe this marking is incorrect...',
                  hintStyle: const TextStyle(color: SasColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: SasColors.glassBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SasColors.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SasColors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SasColors.glassBorderHover),
                  ),
                  counterStyle: const TextStyle(color: SasColors.textMuted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 24),
              
              GlassButton(
                label: 'Submit Dispute',
                isExpanded: true,
                isLoading: _isSubmitting,
                icon: Icons.send_rounded,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
