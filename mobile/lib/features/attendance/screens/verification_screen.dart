
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/core/attendance_constants.dart';
import 'package:smart_attendance_app/core/attendance_utils.dart';
import 'package:smart_attendance_app/data/local/preferences_service.dart';
import 'package:smart_attendance_app/data/local/hive_service.dart';
import 'package:smart_attendance_app/data/repositories/config_repository.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';
import 'package:smart_attendance_app/features/attendance/providers/attendance_provider.dart';
import 'package:smart_attendance_app/features/attendance/providers/geofence_verification_provider.dart';
import 'package:smart_attendance_app/features/attendance/widgets/geofence_status_card.dart';
import 'package:smart_attendance_app/utils/logger.dart';
import 'package:smart_attendance_app/features/home/providers/session_provider.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';

class ImageQuality {
  final double brightness;
  final double blur;
  const ImageQuality({required this.brightness, required this.blur});
}

ImageQuality _computeImageQuality(String imagePath) {
  try {
    final bytes = File(imagePath).readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image == null) return const ImageQuality(brightness: 0, blur: 0);
    
    final resized = img.copyResize(image, width: 100);
    double totalLuminance = 0;
    
    for (final p in resized) {
      final r = p.r / 255.0;
      final g = p.g / 255.0;
      final b = p.b / 255.0;
      totalLuminance += (0.299 * r + 0.587 * g + 0.114 * b);
    }
    double brightness = totalLuminance / (resized.width * resized.height);

    double sumVar = 0;
    double sumSq = 0;
    int count = 0;
    for (int y = 0; y < resized.height - 1; y++) {
      for (int x = 0; x < resized.width - 1; x++) {
        final p1 = resized.getPixel(x, y);
        final p2 = resized.getPixel(x + 1, y);
        final p3 = resized.getPixel(x, y + 1);
        
        final l1 = 0.299 * p1.r + 0.587 * p1.g + 0.114 * p1.b;
        final l2 = 0.299 * p2.r + 0.587 * p2.g + 0.114 * p2.b;
        final l3 = 0.299 * p3.r + 0.587 * p3.g + 0.114 * p3.b;

        final diffX = (l1 - l2) / 255.0;
        final diffY = (l1 - l3) / 255.0;
        final lap = diffX.abs() + diffY.abs();
        
        sumVar += lap;
        sumSq += lap * lap;
        count++;
      }
    }
    final mean = sumVar / count;
    final variance = (sumSq / count) - (mean * mean);
    
    return ImageQuality(brightness: brightness, blur: variance * 1000); 
  } catch (e) {
    return const ImageQuality(brightness: 0, blur: 0);
  }
}

class VerificationScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const VerificationScreen({super.key, required this.sessionId});
  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  bool _cameraReady = false;
  String? _cameraError;
  int _aiStepIndex = 0;
  Timer? _aiStepTimer;
  Timer? _transitionTimer;
  bool _showTips = false;

  bool _isAnalyzingQuality = false;
  double? _brightnessScore;
  double? _blurScore;
  bool _isInitializing = false;

  static const _aiStepLabels = [
    'Checking face identity...',
    'Verifying liveness...',
    'Analyzing background...',
    'Computing final score...',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFirstUse();
    Future.microtask(() => ref.read(configRepositoryProvider).fetchAndCacheConfig());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _aiStepTimer?.cancel();
    _transitionTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkFirstUse() async {
    final prefs = ref.read(preferencesServiceProvider);
    final isFirst = await prefs.isFirstCameraUse();
    if (isFirst && mounted) {
      setState(() => _showTips = true);
      await prefs.markCameraUsed();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _camera;
    if (cam == null) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (mounted) {
        setState(() => _cameraReady = false);
      }
      _camera = null;
      cam.dispose().catchError((e) {
        AppLogger.error('Error disposing camera: $e');
      });
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializing) return;
    if (_camera != null && _camera!.value.isInitialized) return;

    _isInitializing = true;
    try {
      if (_camera != null) {
        final oldCam = _camera;
        _camera = null;
        await oldCam!.dispose().catchError((e) => null);
      }

      if (!mounted) {
        _isInitializing = false;
        return;
      }

      final cameras = await availableCameras();
      if (!mounted) {
        _isInitializing = false;
        return;
      }

      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No cameras found');
        _isInitializing = false;
        return;
      }

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(front, ResolutionPreset.high, enableAudio: false);
      _camera = controller;

      await controller.initialize();

      if (mounted && _camera == controller) {
        setState(() {
          _cameraReady = true;
          _cameraError = null;
        });
      } else {
        await controller.dispose().catchError((e) => null);
      }
    } catch (e) {
      AppLogger.error('Camera init failed: $e');
      if (mounted) {
        setState(() => _cameraError = 'Camera initialization failed');
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _capturePhoto() async {
    if (_camera == null || !_camera!.value.isInitialized) return;
    try {
      final file = await _camera!.takePicture();
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ref.read(attendanceVerificationProvider.notifier).setImagePath(file.path);
      
      setState(() {
        _isAnalyzingQuality = true;
        _brightnessScore = null;
        _blurScore = null;
      });
      
      compute(_computeImageQuality, file.path).then((quality) {
        if (mounted) {
          setState(() {
            _brightnessScore = quality.brightness;
            _blurScore = quality.blur;
            _isAnalyzingQuality = false;
          });
        }
      });
    } catch (e) {
      AppLogger.error('Capture failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed'), backgroundColor: SasColors.bgSurface),
        );
      }
    }
  }

  Future<void> _analyzePhoto() async {
    final notifier = ref.read(attendanceVerificationProvider.notifier);
    _startAiStepAnimation();
    await notifier.analyze(widget.sessionId);
  }

  Future<void> _confirmAttendance() async {
    final notifier = ref.read(attendanceVerificationProvider.notifier);
    await notifier.confirm(widget.sessionId);
  }

  void _retakePhoto() {
    final cam = _camera;
    _camera = null;
    if (mounted) {
      setState(() {
        _cameraReady = false;
        _cameraError = null;
      });
    }
    if (cam != null) {
      cam.dispose().catchError((e) {
        AppLogger.error('Error disposing camera in retake: $e');
      });
    }
    ref.read(attendanceVerificationProvider.notifier).reset();
    ref.read(geofenceVerificationProvider.notifier).reset();
  }

  void _startAiStepAnimation() {
    _aiStepIndex = 0;
    _aiStepTimer?.cancel();
    _aiStepTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (mounted && _aiStepIndex < _aiStepLabels.length - 1) {
        setState(() => _aiStepIndex++);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vState = ref.watch(attendanceVerificationProvider);
    final geoState = ref.watch(geofenceVerificationProvider);

    final sessionState = ref.watch(sessionProvider);
    final classSession = sessionState.sessions.where(
      (s) => s.sessionId == widget.sessionId,
    ).firstOrNull;

    if (vState.step == VerificationStep.gps && geoState.status == GeofenceStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (classSession != null && classSession.latitude != null && classSession.longitude != null) {
          ref.read(geofenceVerificationProvider.notifier).verifyLocation(
            classLat: classSession.latitude!,
            classLng: classSession.longitude!,
            radius: classSession.radiusMeters ?? 100.0,
          );
        }
      });
    }

    ref.listen<AttendanceVerificationState>(attendanceVerificationProvider,
        (prev, next) {
      if (next.step == VerificationStep.reviewing &&
          prev?.step != VerificationStep.reviewing) {
        _aiStepTimer?.cancel();
      }
      if (next.step == VerificationStep.done &&
          prev?.step != VerificationStep.done) {
        _aiStepTimer?.cancel();
        final submittedId = ref.read(attendanceVerificationProvider.notifier).lastSubmittedSessionId;
        if (submittedId != null) {
          ref.read(sessionProvider.notifier).markSessionSubmitted(submittedId);
        }
        if (mounted) context.go('/result');
      }
    });

    ref.listen<GeofenceVerificationState>(geofenceVerificationProvider, (prev, next) {
      if (vState.step == VerificationStep.gps && next.status == GeofenceStatus.success && (prev?.status != GeofenceStatus.success)) {
        _transitionTimer?.cancel();
        _transitionTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) {
            final config = ref.read(hiveServiceProvider).getSystemConfig();
            
            ref.read(attendanceVerificationProvider.notifier).setGpsLocation(
              next.position!.latitude,
              next.position!.longitude,
              next.position!.accuracy,
            );
            
            if (config.isFaceRecognitionEnabled) {
              _initCamera();
            } else {
              ref.read(attendanceVerificationProvider.notifier).setImagePath('skipped_camera.jpg');
              _analyzePhoto();
            }
          }
        });
      }
    });

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _StepIndicator(current: vState.step),
                const SizedBox(height: 24),

                if (vState.step == VerificationStep.gps) ...[
                  const Spacer(),
                  GeofenceStatusCard(
                    state: geoState,
                    onRetry: () {
                      if (classSession != null && classSession.latitude != null && classSession.longitude != null) {
                        ref.read(geofenceVerificationProvider.notifier).verifyLocation(
                          classLat: classSession.latitude!,
                          classLng: classSession.longitude!,
                          radius: classSession.radiusMeters ?? 100.0,
                        );
                      }
                    },
                  ),
                  const Spacer(),
                ],

                if (vState.step == VerificationStep.camera) ...[
                  
                  if (_showTips)
                    GlassCard(
                      borderColor: SasColors.accentEmerald.withValues(alpha: 0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tips_and_updates_rounded,
                                  color: SasColors.accentEmerald, size: 18),
                              SizedBox(width: 8),
                              Text('Tips for best results',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('• Look straight at the camera\n'
                              '• Ensure good lighting (avoid backlighting)\n'
                              '• Remove glasses if possible\n'
                              '• Keep your full face inside the oval',
                              style: TextStyle(color: SasColors.textSecondary, fontSize: 13, height: 1.6)),
                          const SizedBox(height: 8),
                          GlassButton(
                            label: 'Got it',
                            variant: GlassButtonVariant.ghost,
                            onPressed: () => setState(() => _showTips = false),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: GlassCard(
                        padding: EdgeInsets.zero,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _cameraError != null
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.camera_alt_outlined,
                                          color: SasColors.danger, size: 48),
                                      const SizedBox(height: 12),
                                      Text(_cameraError!,
                                          style: const TextStyle(color: SasColors.danger)),
                                      const SizedBox(height: 16),
                                      GlassButton(
                                        label: 'Retry Camera',
                                        icon: Icons.refresh_rounded,
                                        onPressed: () {
                                          setState(() { _cameraError = null; _cameraReady = false; });
                                          _initCamera();
                                        },
                                      ),
                                    ],
                                  ))
                              : _cameraReady
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CameraPreview(_camera!),
                                        
                                        Center(
                                          child: Container(
                                            width: 220, height: 280,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(110),
                                              border: Border.all(
                                                color: SasColors.accentEmerald.withValues(alpha: 0.5),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                        
                                        Positioned(
                                          bottom: 20,
                                          left: 16,
                                          right: 16,
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: SasColors.bgSurface.withValues(alpha: 0.8),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: SasColors.glassBorder,
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.face_retouching_natural_rounded,
                                                    color: SasColors.accentEmerald,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Position face inside frame',
                                                    style: TextStyle(
                                                      color: SasColors.textPrimary,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator(color: SasColors.accentEmerald)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (!_showTips)
                    Row(children: [
                      Expanded(
                        child: GlassButton(
                          label: 'Cancel',
                          variant: GlassButtonVariant.ghost,
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassButton(
                          label: 'Capture',
                          icon: Icons.camera_alt_rounded,
                          onPressed: _cameraReady ? _capturePhoto : null,
                        ),
                      ),
                    ]),
                ],

                if (vState.step == VerificationStep.preview) ...[
                  Expanded(
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (vState.imagePath != null)
                              Image.file(File(vState.imagePath!), fit: BoxFit.cover),
                            
                            Center(
                              child: Container(
                                width: 220, height: 280,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(110),
                                  border: Border.all(
                                    color: SasColors.accentEmerald.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            
                            Positioned(
                              top: 16, left: 0, right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: SasColors.bgSurface.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Review your photo',
                                      style: TextStyle(color: SasColors.textPrimary,
                                          fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quality Check (Estimate):',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 12),
                        if (_isAnalyzingQuality)
                          const Center(
                              child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: SasColors.accentEmerald)),
                          ))
                        else ...[
                          _QualityBar(
                            label: 'Lighting',
                            value: _brightnessScore ?? 0,
                            goodThreshold: 0.3,
                          ),
                          const SizedBox(height: 12),
                          _QualityBar(
                            label: 'Sharpness',
                            value: ((_blurScore ?? 0) / 10).clamp(0.0, 1.0), 
                            goodThreshold: 0.3,
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_brightnessScore != null && (_brightnessScore! < kMinBrightnessForPhoto || ((_blurScore ?? 0) / 10).clamp(0.0, 1.0) < kMinSharpnessForPhoto))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: SasColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: SasColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: SasColors.warning, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Photo too dark or blurry — please retake',
                                  style: TextStyle(color: SasColors.warning, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Row(children: [
                    Expanded(
                      child: GlassButton(
                        label: 'Retake',
                        variant: GlassButtonVariant.secondary,
                        icon: Icons.refresh_rounded,
                        onPressed: _retakePhoto,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassButton(
                        label: 'Analyze',
                        icon: Icons.auto_awesome_rounded,
                        onPressed: (_brightnessScore != null && (_brightnessScore! < kMinBrightnessForPhoto || ((_blurScore ?? 0) / 10).clamp(0.0, 1.0) < kMinSharpnessForPhoto)) ? null : _analyzePhoto,
                      ),
                    ),
                  ]),
                ],

                if (vState.step == VerificationStep.submitting) ...[
                  const Spacer(),
                  GlassCard(
                    child: Column(children: [
                      const SizedBox(height: 24),
                      const SizedBox(width: 48, height: 48,
                          child: CircularProgressIndicator(strokeWidth: 3, color: SasColors.accentEmerald)),
                      const SizedBox(height: 16),
                      const Text('Analyzing your submission…',
                          style: TextStyle(color: SasColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(_aiStepLabels[_aiStepIndex],
                            key: ValueKey(_aiStepIndex),
                            style: const TextStyle(color: SasColors.accentEmerald,
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_aiStepLabels.length, (i) {
                          return Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i <= _aiStepIndex ? SasColors.accentEmerald : SasColors.glassBorder,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                  const Spacer(),
                ],

                if (vState.step == VerificationStep.reviewing) ...[
                  const Spacer(),
                  _AiReviewCard(
                    analysis: vState.analysisResult!,
                    imagePath: vState.imagePath,
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: GlassButton(
                        label: 'Retake',
                        variant: GlassButtonVariant.secondary,
                        icon: Icons.refresh_rounded,
                        onPressed: _retakePhoto,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassButton(
                        label: 'Submit',
                        icon: Icons.check_rounded,
                        onPressed: _confirmAttendance,
                      ),
                    ),
                  ]),
                  const Spacer(),
                ],

                if (vState.step == VerificationStep.confirming) ...[
                  const Spacer(),
                  GlassCard(
                    child: Column(children: [
                      const SizedBox(height: 24),
                      const SizedBox(width: 48, height: 48,
                          child: CircularProgressIndicator(strokeWidth: 3, color: SasColors.accentEmerald)),
                      const SizedBox(height: 16),
                      const Text('Submitting attendance…',
                          style: TextStyle(color: SasColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Almost done',
                          style: TextStyle(color: SasColors.accentEmerald,
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 24),
                    ]),
                  ),
                  const Spacer(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final VerificationStep current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    const steps = ['GPS', 'Camera', 'Preview', 'AI Check', 'Submit'];
    
    final currentIdx = switch (current) {
      VerificationStep.gps => 0,
      VerificationStep.camera => 1,
      VerificationStep.preview => 2,
      VerificationStep.submitting => 3,
      VerificationStep.reviewing => 3,
      VerificationStep.confirming => 4,
      VerificationStep.done => 4,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final isCompleted = i < currentIdx;
        final isCurrent = i == currentIdx;
        final isActive = i <= currentIdx;

        // Left line is active if this step is reached (i <= currentIdx)
        final isLeftLineActive = i > 0 && i <= currentIdx;
        // Right line is active if this step is passed (i < currentIdx)
        final isRightLineActive = i < steps.length - 1 && i < currentIdx;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Left connector line
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: i > 0
                          ? (isLeftLineActive ? SasColors.accentEmerald : SasColors.glassBorder)
                          : Colors.transparent,
                    ),
                  ),
                  // Step Node (Circle)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? SasColors.accentEmerald
                          : isCurrent
                              ? SasColors.accentEmerald.withValues(alpha: 0.15)
                              : SasColors.glassBg,
                      border: Border.all(
                        color: isActive
                            ? SasColors.accentEmerald
                            : SasColors.glassBorder,
                        width: isCurrent ? 2 : 1,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: SasColors.accentEmerald.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1.5,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isCurrent
                                    ? SasColors.accentEmerald
                                    : isActive
                                        ? SasColors.textPrimary
                                        : SasColors.textMuted,
                              ),
                            ),
                    ),
                  ),
                  // Right connector line
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: i < steps.length - 1
                          ? (isRightLineActive ? SasColors.accentEmerald : SasColors.glassBorder)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                steps[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent
                      ? SasColors.accentEmerald
                      : isActive
                          ? SasColors.textPrimary
                          : SasColors.textMuted,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Review Card — shown after analysis, before confirmation
// ─────────────────────────────────────────────────────────────────────────────

class _AiReviewCard extends StatefulWidget {
  final AttendanceAnalysisResult analysis;
  final String? imagePath;

  const _AiReviewCard({required this.analysis, this.imagePath});

  @override
  State<_AiReviewCard> createState() => _AiReviewCardState();
}

class _AiReviewCardState extends State<_AiReviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    final overallColor = scoreColor(a.finalAiScore);
    final isPresent = a.wouldBePresent;

    return GlassCard(
      borderColor: overallColor.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: overallColor.withValues(alpha: 0.12),
                  border: Border.all(color: overallColor.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  isPresent ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  color: overallColor, size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Score Review',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: SasColors.textPrimary,
                        )),
                    Text(
                      isPresent
                          ? 'Looks good — ready to submit'
                          : 'Low confidence — may be flagged',
                      style: TextStyle(
                        fontSize: 12,
                        color: overallColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Overall score badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: overallColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: overallColor.withValues(alpha: 0.3)),
                ),
                child: AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (_, __) => Text(
                    '${(a.finalAiScore * 100 * _progressAnim.value).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: overallColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                SasColors.glassBorder,
                Colors.transparent,
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // ── Sub-scores ───────────────────────────────────────────────────
          _ReviewScoreRow(
            label: 'Face Match',
            icon: Icons.face_rounded,
            score: a.faceScore,
            animation: _progressAnim,
            hint: _faceHint(a.faceScore),
          ),
          const SizedBox(height: 10),
          _ReviewScoreRow(
            label: 'Liveness',
            icon: Icons.visibility_rounded,
            score: a.livenessScore,
            animation: _progressAnim,
            hint: _livenessHint(a.livenessScore),
          ),
          const SizedBox(height: 10),
          _ReviewScoreRow(
            label: 'Background',
            icon: Icons.location_city_rounded,
            score: a.backgroundScore,
            animation: _progressAnim,
            hint: _backgroundHint(a.backgroundScore),
          ),

          if (!isPresent) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SasColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SasColors.warning.withValues(alpha: 0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: SasColors.warning, size: 15),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Submitting will mark this as Flagged. Your teacher will review it.',
                      style: TextStyle(
                        color: SasColors.warning,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _faceHint(double score) {
    if (score >= 0.85) return 'Strong match';
    if (score >= kGoodScoreThreshold) return 'Good match';
    if (score >= 0.5) return 'Weak match';
    return 'Poor — try better lighting';
  }

  String _livenessHint(double score) {
    if (score >= 0.8) return 'Confirmed live';
    if (score >= 0.6) return 'Likely live';
    return 'Try better lighting';
  }

  String _backgroundHint(double score) {
    if (score >= kGoodScoreThreshold) return 'Classroom verified';
    return 'Unfamiliar background';
  }
}

class _ReviewScoreRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double score;
  final Animation<double> animation;
  final String hint;

  const _ReviewScoreRow({
    required this.label,
    required this.icon,
    required this.score,
    required this.animation,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(score);
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 76,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: SasColors.textMuted,
                      fontWeight: FontWeight.w500)),
              Text(hint,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: animation,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (score * animation.value).clamp(0.0, 1.0),
                backgroundColor: SasColors.glassBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedBuilder(
          animation: animation,
          builder: (_, __) => Text(
            '${(score * 100 * animation.value).toStringAsFixed(0)}%',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quality Bar
// ─────────────────────────────────────────────────────────────────────────────

class _QualityBar extends StatelessWidget {
  final String label;
  final double value; 
  final double goodThreshold;
  
  const _QualityBar({required this.label, required this.value, required this.goodThreshold});
  
  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final isGood = clamped >= goodThreshold;
    final color = isGood ? SasColors.success : SasColors.warning;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: SasColors.textSecondary)),
            Text(isGood ? 'Good' : 'Suboptimal', 
                 style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: clamped,
          backgroundColor: SasColors.glassBorder,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }
}

