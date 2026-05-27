
import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_app_bar.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      q: 'Why was my attendance flagged?',
      a:
          'Your submission is flagged when the AI confidence score falls below the threshold. Common causes: poor lighting, face partially covered, glasses glare, or an unfamiliar background. Your teacher will review flagged submissions and can approve or reject them.',
    ),
    (
      q: 'What is the liveness check?',
      a:
          'The liveness check verifies that you are physically present and not using a photo. It analyzes eye openness, natural skin texture, and subtle facial movements. Ensure good lighting and look directly at the camera.',
    ),
    (
      q: 'Why does the app need GPS?',
      a:
          'GPS verifies that you are physically inside the classroom geofence set by your teacher. Without location verification, attendance could be marked from anywhere. If GPS accuracy is too low, move to an open area and retry.',
    ),
    (
      q: 'What happens to my attendance if I am offline?',
      a:
          'Your submission is saved locally and will sync automatically when you reconnect to the internet. The submission timestamp is preserved. Submissions expire after 2 hours if not synced, so reconnect as soon as possible.',
    ),
    (
      q: 'Why is my overall percentage lower than expected?',
      a:
          'The overall percentage is calculated as: (sessions marked Present or Approved) ÷ (total sessions across all enrolled classes). Absent sessions count against you even if you did not attempt to mark attendance.',
    ),
    (
      q: 'Can I retake a photo if it looks bad?',
      a:
          'Yes. After capturing a photo, you will see a preview with quality indicators. Tap "Retake" to capture again before submitting. You can retake as many times as needed.',
    ),
    (
      q: 'How do I register my face?',
      a:
          'Face registration happens once after your first login. You will be prompted to take a selfie in good lighting. If your face has changed significantly (e.g., new glasses, beard), contact your administrator to request re-registration.',
    ),
    (
      q: 'What does the AI score mean?',
      a:
          'The AI score is a composite of three checks: Face match (how closely your face matches your registered photo), Liveness (confirming you are physically present), and Background (verifying you are in a learning environment). Scores above 70% are generally strong.',
    ),
    (
      q: 'How do I contact support?',
      a:
          'Contact your institution\'s IT department or the system administrator.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Help & FAQ'),
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                borderColor: SasColors.accentEmerald.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline_rounded,
                        color: SasColors.accentEmerald, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tap any question to expand the answer.',
                        style: TextStyle(
                            color: SasColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ..._faqs.map((faq) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FaqTile(question: faq.q, answer: faq.a),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            widget.question,
            style: const TextStyle(
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
          children: [
            Text(
              widget.answer,
              style: const TextStyle(
                  color: SasColors.textSecondary,
                  fontSize: 13,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
