import 'dart:math' as math;
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

class _GeofenceStatusCardState extends State<GeofenceStatusCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _radarController;
  late AnimationController _entryController;
  late Animation<double> _pulseAnim;
  late Animation<double> _radarAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _radarAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _radarController, curve: Curves.linear),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _radarController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.status == GeofenceStatus.idle) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) => FadeTransition(
        opacity: _fadeAnim,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: child,
        ),
      ),
      child: _buildCard(),
    );
  }

  Widget _buildCard() {
    final status = widget.state.status;

    Color statusColor;
    String statusTitle;
    String statusDesc;

    switch (status) {
      case GeofenceStatus.scanning:
        statusColor = SasColors.info;
        statusTitle = 'Acquiring Location';
        statusDesc = 'Verifying you are inside the classroom boundary...';
        break;
      case GeofenceStatus.success:
        statusColor = SasColors.success;
        statusTitle = 'Location Verified';
        statusDesc = 'You are inside the classroom boundary.';
        break;
      case GeofenceStatus.failed:
        statusColor = SasColors.danger;
        statusTitle = 'Location Failed';
        statusDesc = widget.state.errorMessage ?? 'Could not verify your location.';
        break;
      default:
        statusColor = SasColors.textMuted;
        statusTitle = 'Unknown';
        statusDesc = '';
    }

    return GlassCard(
      borderColor: statusColor.withValues(alpha: 0.35),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconSection(status, statusColor),
          const SizedBox(height: 20),
          Text(
            statusTitle,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: statusColor,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            statusDesc,
            style: const TextStyle(
              color: SasColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.state.distanceMeters != null &&
              widget.state.radiusMeters != null) ...[
            const SizedBox(height: 20),
            _buildDistanceMetrics(statusColor),
          ],
          if (status == GeofenceStatus.failed) ...[
            const SizedBox(height: 20),
            GlassButton(
              label: 'Retry Location',
              icon: Icons.refresh_rounded,
              isExpanded: true,
              onPressed: widget.onRetry,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconSection(GeofenceStatus status, Color color) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, _) => Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.12 * _pulseAnim.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Radar sweep (scanning only)
          if (status == GeofenceStatus.scanning)
            AnimatedBuilder(
              animation: _radarAnim,
              builder: (context, _) => CustomPaint(
                size: const Size(80, 80),
                painter: _RadarPainter(
                  progress: _radarAnim.value,
                  color: color,
                ),
              ),
            ),
          // Inner circle
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) => Opacity(
                opacity: status == GeofenceStatus.scanning
                    ? 0.6 + (0.4 * _pulseAnim.value)
                    : 1.0,
                child: child,
              ),
              child: Icon(
                _iconForStatus(status),
                color: color,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForStatus(GeofenceStatus status) {
    switch (status) {
      case GeofenceStatus.scanning:
        return Icons.radar_rounded;
      case GeofenceStatus.success:
        return Icons.task_alt_rounded;
      case GeofenceStatus.failed:
        return Icons.location_off_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _buildDistanceMetrics(Color statusColor) {
    final distance = widget.state.distanceMeters!;
    final radius = widget.state.radiusMeters!;
    final progress = (distance / radius).clamp(0.0, 1.5);
    final isInside = widget.state.status == GeofenceStatus.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SasColors.glassBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _MetricChip(
                label: 'Your Distance',
                value: '${distance.toStringAsFixed(0)}m',
                icon: Icons.near_me_rounded,
                color: statusColor,
              ),
              const SizedBox(width: 10),
              _MetricChip(
                label: 'Allowed Radius',
                value: '${radius.toStringAsFixed(0)}m',
                icon: Icons.radio_button_checked_rounded,
                color: SasColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Distance bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Distance to boundary',
                    style: TextStyle(
                      fontSize: 11,
                      color: SasColors.textMuted,
                    ),
                  ),
                  Text(
                    isInside ? 'Inside ✓' : 'Outside ✗',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (progress / 1.5).clamp(0.0, 1.0),
                  backgroundColor: SasColors.glassBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          if (widget.state.accuracy != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gps_fixed_rounded,
                    color: SasColors.textMuted, size: 12),
                const SizedBox(width: 4),
                Text(
                  'GPS Accuracy: ±${widget.state.accuracy!.toStringAsFixed(0)}m',
                  style: const TextStyle(
                    color: SasColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 12),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: SasColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Radar Sweep Painter
// ─────────────────────────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RadarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Sweep arc
    final sweepAngle = math.pi * 0.8;
    final startAngle = (progress * 2 * math.pi) - math.pi / 2;

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.5),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
      )
      ..close();

    canvas.drawPath(path, sweepPaint);

    // Leading dot
    final dotAngle = startAngle + sweepAngle;
    final dotX = center.dx + radius * 0.85 * math.cos(dotAngle);
    final dotY = center.dy + radius * 0.85 * math.sin(dotAngle);
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dotX, dotY), 3, dotPaint);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.progress != progress;
}
