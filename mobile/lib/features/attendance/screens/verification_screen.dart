
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/core/constants.dart';
import 'package:smart_attendance_app/data/local/preferences_service.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:smart_attendance_app/features/attendance/providers/attendance_provider.dart';
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
  String? _locationError;
  String? _cameraError;
  int _aiStepIndex = 0;
  Timer? _aiStepTimer;
  bool _showTips = false;
  
  bool _isAnalyzingQuality = false;
  double? _brightnessScore;
  double? _blurScore;

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
    _acquireGps();
    _checkFirstUse();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _aiStepTimer?.cancel();
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
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      setState(() => _cameraReady = false);
      cam.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _acquireGps() async {
    setState(() => _locationError = null);
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        setState(() => _locationError = 'Location services are disabled on device');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          setState(() => _locationError = 'Location permission denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationError = 'Location permanently denied. Enable in settings');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (pos.accuracy > kMinGpsAccuracyMeters) {
        setState(() => _locationError =
            'GPS accuracy too low (${pos.accuracy.toStringAsFixed(0)}m). Move to an open area and retry.');
        return;
      }
      ref.read(attendanceVerificationProvider.notifier)
          .setGpsLocation(pos.latitude, pos.longitude);
      _initCamera();
    } catch (e, st) {
      debugPrint('_acquireGps error: $e\n$st');
      setState(() => _locationError = 'Failed to get location');
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) { setState(() => _cameraError = 'No cameras found'); return; }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _camera = CameraController(front, ResolutionPreset.high, enableAudio: false);
      await _camera!.initialize();
      if (mounted) {
        setState(() => _cameraReady = true);
      }
    } catch (e, st) {
      debugPrint('_initCamera error: $e\n$st');
      if (mounted) setState(() => _cameraError = 'Camera initialization failed');
    }
  }

  Future<void> _capturePhoto() async {
    if (_camera == null || !_camera!.value.isInitialized) return;
    try {
      final file = await _camera!.takePicture();
      HapticFeedback.mediumImpact();
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
    } catch (e, st) {
      debugPrint('_capturePhoto error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e'), backgroundColor: SasColors.bgSurface),
        );
      }
    }
  }

  Future<void> _submitPhoto() async {
    final notifier = ref.read(attendanceVerificationProvider.notifier);
    notifier.confirmSubmit();
    _startAiStepAnimation();
    await notifier.submit(widget.sessionId);
  }

  void _retakePhoto() {
    ref.read(attendanceVerificationProvider.notifier).reset();
    _acquireGps();
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

    ref.listen<AttendanceVerificationState>(attendanceVerificationProvider,
        (prev, next) {
      if (next.step == VerificationStep.done &&
          prev?.step != VerificationStep.done) {
        _aiStepTimer?.cancel();
        if (mounted) context.go('/result');
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
                  GlassCard(
                    child: Column(children: [
                      const SizedBox(height: 16),
                      if (_locationError != null) ...[
                        const Icon(Icons.location_off_rounded, color: SasColors.danger, size: 48),
                        const SizedBox(height: 12),
                        Text(_locationError!, style: const TextStyle(color: SasColors.danger),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        GlassButton(label: 'Retry', onPressed: _acquireGps, icon: Icons.refresh_rounded),
                      ] else ...[
                        const SizedBox(width: 48, height: 48,
                            child: CircularProgressIndicator(strokeWidth: 3, color: SasColors.accentEmerald)),
                        const SizedBox(height: 16),
                        const Text('Verifying location…',
                            style: TextStyle(color: SasColors.textSecondary, fontSize: 16)),
                      ],
                      const SizedBox(height: 16),
                    ]),
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
                        onPressed: _submitPhoto,
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
    const steps = ['GPS', 'Camera', 'Review', 'Submit'];
    
    final currentIdx = switch (current) {
      VerificationStep.gps => 0,
      VerificationStep.camera => 1,
      VerificationStep.preview => 2,
      VerificationStep.submitting => 3,
      VerificationStep.done => 3,
    };
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i <= currentIdx;
        return Expanded(
          child: Column(
            children: [
              Row(children: [
                if (i > 0)
                  Expanded(child: Container(height: 2,
                      color: isActive ? SasColors.accentEmerald : SasColors.glassBorder)),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? SasColors.accentEmerald.withValues(alpha: 0.2) : SasColors.glassBg,
                    border: Border.all(color: isActive ? SasColors.accentEmerald : SasColors.glassBorder),
                  ),
                  child: Center(child: Text('${i + 1}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: isActive ? SasColors.accentEmerald : SasColors.textMuted))),
                ),
              ]),
              const SizedBox(height: 4),
              Text(steps[i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: isActive ? SasColors.accentEmerald : SasColors.textMuted)),
            ],
          ),
        );
      }),
    );
  }
}

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
