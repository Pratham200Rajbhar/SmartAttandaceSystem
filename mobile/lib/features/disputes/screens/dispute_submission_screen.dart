// Dispute Submission Screen - Submit dispute with reason and proof image
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_app_bar.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class DisputeSubmissionScreen extends ConsumerStatefulWidget {
  final String attendanceId;
  final String className;
  final String subject;

  const DisputeSubmissionScreen({
    super.key,
    required this.attendanceId,
    required this.className,
    required this.subject,
  });

  @override
  ConsumerState<DisputeSubmissionScreen> createState() =>
      _DisputeSubmissionScreenState();
}

class _DisputeSubmissionScreenState
    extends ConsumerState<DisputeSubmissionScreen> {
  String _selectedReason = 'GPS Inaccurate';
  final _proofUrlController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

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
    _proofUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitDispute() async {
    if (_notesController.text.trim().isEmpty) {
      _showError('Please provide additional details');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(studentApiProvider).submitDispute(
            attendanceId: widget.attendanceId,
            reason: '$_selectedReason: ${_notesController.text.trim()}',
            proofImagePath: _proofUrlController.text.trim().isEmpty
                ? null
                : null, // TODO: Implement image picker for actual file path
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispute submitted successfully!'),
            backgroundColor: SasColors.success,
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to submit dispute: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SasColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Submit Dispute'),
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              GlassCard(
                borderColor: SasColors.warning.withValues(alpha: 0.4),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SasColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.gavel_rounded,
                          color: SasColors.warning, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.className,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.subject,
                      style: const TextStyle(
                        color: SasColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Submit evidence to support your case',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SasColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Reason Selection
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
                          horizontal: 16, vertical: 10),
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
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Proof Image URL (Optional)
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
              GlassCard(
                padding: const EdgeInsets.all(0),
                child: TextField(
                  controller: _proofUrlController,
                  style: const TextStyle(
                      color: SasColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'https://imgur.com/... or Google Drive link',
                    hintStyle:
                        TextStyle(color: SasColors.textMuted, fontSize: 13),
                    prefixIcon: Icon(Icons.image_outlined,
                        color: SasColors.textMuted, size: 20),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Additional Details (Required)
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
              GlassCard(
                padding: const EdgeInsets.all(0),
                child: TextField(
                  controller: _notesController,
                  maxLines: 5,
                  maxLength: 500,
                  style: const TextStyle(
                      color: SasColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText:
                        'Explain what happened and why you believe the attendance marking was incorrect...',
                    hintStyle:
                        TextStyle(color: SasColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    counterStyle:
                        TextStyle(color: SasColors.textMuted, fontSize: 11),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              GlassButton(
                label: 'Submit Dispute',
                isExpanded: true,
                isLoading: _isSubmitting,
                icon: Icons.send_rounded,
                onPressed: _isSubmitting ? null : _submitDispute,
              ),

              const SizedBox(height: 12),

              // Info Card
              GlassCard(
                borderColor: SasColors.info.withValues(alpha: 0.3),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: SasColors.info, size: 18),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your teacher will review your dispute and supporting evidence. You\'ll be notified of the decision.',
                        style: TextStyle(
                          color: SasColors.textMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
