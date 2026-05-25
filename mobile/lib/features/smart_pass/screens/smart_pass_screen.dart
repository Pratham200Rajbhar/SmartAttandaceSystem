
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/features/smart_pass/providers/smart_pass_provider.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class SmartPassScreen extends ConsumerStatefulWidget {
  const SmartPassScreen({super.key});

  @override
  ConsumerState<SmartPassScreen> createState() => _SmartPassScreenState();
}

class _SmartPassScreenState extends ConsumerState<SmartPassScreen> {
  Timer? _countdownTimer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    
    Future.microtask(() {
      ref.read(smartPassProvider.notifier).generatePass();
      ref.read(smartPassProvider.notifier).startAutoRefresh();
    });
    
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _secondsRemaining = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsRemaining = (_secondsRemaining - 1).clamp(0, 30);
          if (_secondsRemaining == 0) {
            _secondsRemaining = 30; 
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    ref.read(smartPassProvider.notifier).stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passState = ref.watch(smartPassProvider);

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Smart Pass',
              style: TextStyle(fontWeight: FontWeight.w700)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: passState.isLoading && passState.pass == null
              ? _buildLoadingState()
              : passState.errorMessage != null
                  ? _buildErrorState(passState.errorMessage!)
                  : passState.pass != null
                      ? _buildPassCard(passState.pass!)
                      : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: SasColors.accentEmerald.withValues(alpha: 0.3),
            highlightColor: SasColors.accentEmerald,
            child: const Icon(Icons.qr_code_2_rounded, size: 120),
          ),
          const SizedBox(height: 24),
          const Text('Generating Smart Pass...',
              style: TextStyle(color: SasColors.textMuted, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: SasColors.danger),
              const SizedBox(height: 16),
              Text(error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: SasColors.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(smartPassProvider.notifier).generatePass(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SasColors.accentEmerald,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassCard(pass) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          
          Stack(
            alignment: Alignment.center,
            children: [
              Shimmer.fromColors(
                baseColor: SasColors.accentEmerald.withValues(alpha: 0.1),
                highlightColor: SasColors.accentEmerald.withValues(alpha: 0.3),
                period: const Duration(seconds: 2),
                child: Container(
                  width: double.infinity,
                  height: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        SasColors.accentEmerald.withValues(alpha: 0.2),
                        SasColors.accentTeal.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              ),
              GlassCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: pass.qrToken,
                        version: QrVersions.auto,
                        size: 240,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      pass.studentName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: SasColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pass.enrollmentNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        color: SasColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _secondsRemaining <= 10
                            ? SasColors.danger.withValues(alpha: 0.2)
                            : SasColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _secondsRemaining <= 10
                              ? SasColors.danger
                              : SasColors.success,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            size: 20,
                            color: _secondsRemaining <= 10
                                ? SasColors.danger
                                : SasColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Expires in $_secondsRemaining seconds',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _secondsRemaining <= 10
                                  ? SasColors.danger
                                  : SasColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SasColors.info.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info_outline_rounded,
                          size: 20, color: SasColors.info),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'How to Use',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoItem('Show this QR code to campus security or staff'),
                _buildInfoItem('Code refreshes automatically every 30 seconds'),
                _buildInfoItem('Do not share screenshots - they won\'t work'),
                _buildInfoItem('Valid only while displayed in this app'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 16, color: SasColors.accentEmerald),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: SasColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
