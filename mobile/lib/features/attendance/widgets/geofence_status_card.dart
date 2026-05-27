import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/features/attendance/providers/geofence_verification_provider.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';

class GeofenceStatusCard extends StatefulWidget {
  final GeofenceVerificationState state;
  final VoidCallback onRetry;

  const GeofenceStatusCard({
    super.key,
    required this.state,
    required this.onRetry,
  });

  @override
  State<GeofenceStatusCard> createState() => _GeofenceStatusCardState();
}

class _GeofenceStatusCardState extends State<GeofenceStatusCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.status == GeofenceStatus.idle) {
      return const SizedBox.shrink();
    }

    Color statusColor;
    IconData statusIcon;
    String statusTitle;

    switch (widget.state.status) {
      case GeofenceStatus.scanning:
        statusColor = SasColors.info;
        statusIcon = Icons.radar_rounded;
        statusTitle = 'Acquiring Secure Location...';
        break;
      case GeofenceStatus.success:
        statusColor = SasColors.success;
        statusIcon = Icons.task_alt_rounded;
        statusTitle = 'Inside Classroom Boundary';
        break;
      case GeofenceStatus.failed:
        statusColor = SasColors.danger;
        statusIcon = Icons.location_off_rounded;
        statusTitle = 'Location Verification Failed';
        break;
      default:
        statusColor = SasColors.textMuted;
        statusIcon = Icons.help_outline_rounded;
        statusTitle = 'Unknown Status';
    }

    return GlassCard(
      borderColor: statusColor.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Icon & Title
            if (widget.state.status == GeofenceStatus.scanning)
              FadeTransition(
                opacity: _pulseAnimation,
                child: Icon(statusIcon, color: statusColor, size: 48),
              )
            else
              Icon(statusIcon, color: statusColor, size: 48),
              
            const SizedBox(height: 16),
            
            Text(
              statusTitle,
              style: TextStyle(
                color: statusColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),

            // Metrics / Error Message
            if (widget.state.status == GeofenceStatus.failed && widget.state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.state.errorMessage!,
                  style: const TextStyle(
                    color: SasColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            if (widget.state.distanceMeters != null && widget.state.radiusMeters != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: SasRadius.mdAll,
                  border: Border.all(color: SasColors.glassBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Distance', style: TextStyle(color: SasColors.textMuted, fontSize: 13)),
                    Text(
                      '${widget.state.distanceMeters!.toStringAsFixed(0)}m / ${widget.state.radiusMeters!.toStringAsFixed(0)}m',
                      style: TextStyle(
                        color: widget.state.status == GeofenceStatus.success ? SasColors.success : SasColors.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.state.accuracy != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'GPS Accuracy: ±${widget.state.accuracy!.toStringAsFixed(0)}m',
                    style: const TextStyle(color: SasColors.textMuted, fontSize: 11),
                  ),
                ),
            ],

            // Actions
            if (widget.state.status == GeofenceStatus.failed) ...[
              const SizedBox(height: 24),
              GlassButton(
                label: 'Retry Location',
                icon: Icons.refresh_rounded,
                isExpanded: true,
                onPressed: widget.onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
