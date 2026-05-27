
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/features/auth/providers/auth_provider.dart';
import 'package:smart_attendance_app/features/registration/providers/registration_provider.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/utils/logger.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class FaceRegistrationScreen extends ConsumerStatefulWidget {
  const FaceRegistrationScreen({super.key});
  @override
  ConsumerState<FaceRegistrationScreen> createState() =>
      _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState
    extends ConsumerState<FaceRegistrationScreen> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  String? _capturedPath;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No cameras found on this device');
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController =
          CameraController(front, ResolutionPreset.high, enableAudio: false);
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      AppLogger.error('Camera init failed: $e');
      if (mounted) {
        setState(() => _cameraError = 'Camera initialization failed: $e');
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final file = await _cameraController!.takePicture();
      setState(() => _capturedPath = file.path);
    } catch (e) {
      AppLogger.error('Capture failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: SasColors.bgSurface,
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto() async {
    if (_capturedPath == null) return;
    final success =
        await ref.read(registrationProvider.notifier).uploadFace(_capturedPath!);
    if (success && mounted) {
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xE605050A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SasColors.glassBorder),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: SasColors.success,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Face Registered!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: SasColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Identity bound successfully.\nRedirecting to Home...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: SasColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        ref.read(authProvider.notifier).onFaceRegistered();
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationProvider);
    final isUploading = regState.status == RegistrationStatus.uploading;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.face_retouching_natural_rounded,
                    color: SasColors.accentEmerald, size: 40),
                const SizedBox(height: 12),
                Text('Secure Profile Setup',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Look straight into the camera.\nThis photo locks your identity permanently.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SasColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _capturedPath != null
                          ? Image.file(File(_capturedPath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity)
                          : _cameraError != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.camera_alt_outlined,
                                            color: SasColors.danger, size: 48),
                                        const SizedBox(height: 12),
                                        Text(_cameraError!,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                color: SasColors.danger,
                                                fontSize: 14)),
                                        const SizedBox(height: 16),
                                        GlassButton(
                                          label: 'Retry',
                                          icon: Icons.refresh_rounded,
                                          onPressed: () {
                                            setState(() {
                                              _cameraError = null;
                                              _isCameraReady = false;
                                            });
                                            _initCamera();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : _isCameraReady
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CameraPreview(_cameraController!),
                                        
                                        Center(
                                          child: Container(
                                            width: 220,
                                            height: 280,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(110),
                                              border: Border.all(
                                                color: SasColors.accentEmerald
                                                    .withValues(alpha: 0.5),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        color: SasColors.accentEmerald,
                                      ),
                                    ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (regState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SasColors.accentPink.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: SasColors.accentPink.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: SasColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(regState.errorMessage!,
                                style: const TextStyle(
                                    color: SasColors.danger, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_capturedPath == null)
                  GlassButton(
                    label: 'Capture Photo',
                    isExpanded: true,
                    icon: Icons.camera_alt_rounded,
                    onPressed: _isCameraReady ? _capturePhoto : null,
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          label: 'Retake',
                          variant: GlassButtonVariant.secondary,
                          icon: Icons.refresh_rounded,
                          onPressed: isUploading
                              ? null
                              : () => setState(() => _capturedPath = null),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassButton(
                          label: 'Upload',
                          isLoading: isUploading,
                          icon: Icons.cloud_upload_rounded,
                          onPressed: isUploading ? null : _uploadPhoto,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
