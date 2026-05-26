
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_app_bar.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';
import 'package:smart_attendance_app/utils/logger.dart';

class LeaveRequestsScreen extends ConsumerStatefulWidget {
  const LeaveRequestsScreen({super.key});

  @override
  ConsumerState<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends ConsumerState<LeaveRequestsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedReason = 'Medical';
  final _notesController = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedDocument;
  bool _isSubmitting = false;

  final List<String> _reasonOptions = [
    'Medical',
    'Family Emergency',
    'Personal',
    'Academic',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: SasColors.accentEmerald,
            onPrimary: Colors.white,
            surface: SasColors.bgSecondary,
            onSurface: SasColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: SasColors.accentEmerald,
            onPrimary: Colors.white,
            surface: SasColors.bgSecondary,
            onSurface: SasColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _pickDocument(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedDocument = File(pickedFile.path);
        });
      }
    } catch (e) {
      AppLogger.error('Error picking document: $e');
    }
  }

  Future<void> _submitRequest() async {
    if (_startDate == null || _endDate == null) {
      _showError('Please select start and end dates');
      return;
    }

    final reasonText = _notesController.text.trim();
    final finalReason = reasonText.isEmpty
        ? _selectedReason
        : '$_selectedReason: $reasonText';

    setState(() => _isSubmitting = true);
    try {
      await ref.read(studentApiProvider).createLeaveRequest(
            startDate: _startDate!,
            endDate: _endDate!,
            reason: finalReason,
            documentPath: _selectedDocument?.path,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request submitted successfully!'),
            backgroundColor: SasColors.success,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      AppLogger.error('Failed to submit request: $e');
      if (mounted) {
        _showError('Something went wrong. Please try again.');
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
    final dayCount = _startDate != null && _endDate != null
        ? _endDate!.difference(_startDate!).inDays + 1
        : 0;

    return Scaffold(
      appBar: const GlassAppBar(title: 'Request Leave'),
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SasColors.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event_note_rounded,
                          color: SasColors.info, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leave Application',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Fill in the details below',
                            style: TextStyle(
                              color: SasColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'LEAVE PERIOD',
                style: TextStyle(
                  color: SasColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      onTap: _selectStartDate,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 14, color: SasColors.textMuted),
                              SizedBox(width: 6),
                              Text(
                                'Start Date',
                                style: TextStyle(
                                  color: SasColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _startDate != null
                                ? DateFormat('MMM d, yyyy').format(_startDate!)
                                : 'Select date',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _startDate != null
                                  ? SasColors.textPrimary
                                  : SasColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      onTap: _selectEndDate,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.event_rounded,
                                  size: 14, color: SasColors.textMuted),
                              SizedBox(width: 6),
                              Text(
                                'End Date',
                                style: TextStyle(
                                  color: SasColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _endDate != null
                                ? DateFormat('MMM d, yyyy').format(_endDate!)
                                : 'Select date',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _endDate != null
                                  ? SasColors.textPrimary
                                  : SasColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (dayCount > 0) ...[
                const SizedBox(height: 8),
                GlassCard(
                  borderColor: SasColors.info.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: SasColors.info),
                      const SizedBox(width: 8),
                      Text(
                        '$dayCount ${dayCount == 1 ? 'day' : 'days'} of leave',
                        style: const TextStyle(
                          color: SasColors.info,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              const Text(
                'REASON',
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
                            ? SasColors.accentEmerald.withValues(alpha: 0.2)
                            : SasColors.glassBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? SasColors.accentEmerald.withValues(alpha: 0.5)
                              : SasColors.glassBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        reason,
                        style: TextStyle(
                          color: isSelected
                              ? SasColors.accentEmerald
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

              const Text(
                'MEDICAL CERTIFICATE / DOCUMENT (OPTIONAL)',
                style: TextStyle(
                  color: SasColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedDocument != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedDocument!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDocument = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedDocument!.path.split('/').last,
                  style: const TextStyle(
                    color: SasColors.textMuted,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDocument(ImageSource.gallery),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: SasColors.glassBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SasColors.glassBorder),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.photo_library_outlined,
                                  color: SasColors.textMuted, size: 28),
                              SizedBox(height: 8),
                              Text(
                                'Select from Gallery',
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
                        onTap: () => _pickDocument(ImageSource.camera),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: SasColors.glassBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SasColors.glassBorder),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  color: SasColors.textMuted, size: 28),
                              SizedBox(height: 8),
                              Text(
                                'Capture with Camera',
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
                'ADDITIONAL NOTES (OPTIONAL)',
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
                  maxLines: 4,
                  maxLength: 500,
                  style: const TextStyle(
                      color: SasColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Any additional information...',
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

              GlassButton(
                label: 'Submit Request',
                isExpanded: true,
                isLoading: _isSubmitting,
                icon: Icons.send_rounded,
                onPressed: _isSubmitting ? null : _submitRequest,
              ),

              const SizedBox(height: 12),

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
                        'Your request will be reviewed by your teacher. You\'ll receive a notification once it\'s processed.',
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
