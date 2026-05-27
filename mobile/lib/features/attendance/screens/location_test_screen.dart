import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/data/local/location_service.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({super.key});

  @override
  State<LocationTestScreen> createState() => _LocationTestScreenState();
}

class _LocationTestScreenState extends State<LocationTestScreen> {
  final LocationService _locationService = LocationService();
  
  // Status states
  bool _serviceEnabled = false;
  LocationPermission _permissionStatus = LocationPermission.denied;
  
  // Test states
  bool _isLoading = false;
  String _testType = 'None';
  String _durationMs = 'N/A';
  Position? _acquiredPosition;
  String? _errorMessage;

  // Stream state
  StreamSubscription<Position>? _positionStreamSub;
  final List<Position> _streamedPositions = [];
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    _checkSystemStatus();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    super.dispose();
  }

  Future<void> _checkSystemStatus() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      final perm = await Geolocator.checkPermission();
      setState(() {
        _serviceEnabled = enabled;
        _permissionStatus = perm;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Status check failed: $e';
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _locationService.ensurePermissionsGranted();
      await _checkSystemStatus();
    } catch (e) {
      setState(() {
        _errorMessage = 'Permission error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runSingleAttemptTest() async {
    setState(() {
      _isLoading = true;
      _testType = 'LocationService Wrapper';
      _errorMessage = null;
      _acquiredPosition = null;
      _durationMs = 'N/A';
    });
    final stopwatch = Stopwatch()..start();
    try {
      final pos = await _locationService.getHighlyAccuratePosition();
      stopwatch.stop();
      setState(() {
        _acquiredPosition = pos;
        _durationMs = '${stopwatch.elapsedMilliseconds} ms';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _errorMessage = 'Test failed in ${stopwatch.elapsedMilliseconds}ms:\n$e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runRawGeolocatorTest() async {
    setState(() {
      _isLoading = true;
      _testType = 'Raw Geolocator Direct';
      _errorMessage = null;
      _acquiredPosition = null;
      _durationMs = 'N/A';
    });
    final stopwatch = Stopwatch()..start();
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      stopwatch.stop();
      setState(() {
        _acquiredPosition = pos;
        _durationMs = '${stopwatch.elapsedMilliseconds} ms';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _errorMessage = 'Raw query failed in ${stopwatch.elapsedMilliseconds}ms:\n$e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _togglePositionStream() {
    if (_isStreaming) {
      _positionStreamSub?.cancel();
      setState(() {
        _isStreaming = false;
      });
    } else {
      setState(() {
        _isStreaming = true;
        _streamedPositions.clear();
        _errorMessage = null;
      });
      _positionStreamSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).listen(
        (Position position) {
          setState(() {
            _streamedPositions.insert(0, position);
            if (_streamedPositions.length > 10) {
              _streamedPositions.removeLast();
            }
          });
        },
        onError: (e) {
          setState(() {
            _errorMessage = 'Stream error: $e';
            _isStreaming = false;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Location Diagnostics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // System Info Card
              _buildSectionHeader('Device System Status'),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        label: 'GPS Hardware Service',
                        value: _serviceEnabled ? 'ENABLED' : 'DISABLED',
                        valueColor: _serviceEnabled ? SasColors.success : SasColors.danger,
                      ),
                      const Divider(color: SasColors.glassBorder),
                      _buildInfoRow(
                        label: 'App Permission Status',
                        value: _permissionStatus.toString().split('.').last.toUpperCase(),
                        valueColor: _permissionStatus == LocationPermission.always || 
                                   _permissionStatus == LocationPermission.whileInUse
                            ? SasColors.success
                            : SasColors.warning,
                      ),
                      const SizedBox(height: 16),
                      GlassButton(
                        label: 'Refresh Status',
                        isExpanded: true,
                        onPressed: _checkSystemStatus,
                      ),
                      const SizedBox(height: 8),
                      GlassButton(
                        label: 'Request Location Permissions',
                        isExpanded: true,
                        onPressed: _requestPermissions,
                      ),
                      const SizedBox(height: 8),
                      GlassButton(
                        label: 'Open App Settings',
                        isExpanded: true,
                        onPressed: () => Geolocator.openAppSettings(),
                      ),
                      const SizedBox(height: 8),
                      GlassButton(
                        label: 'Open GPS Settings',
                        isExpanded: true,
                        onPressed: () => Geolocator.openLocationSettings(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Active Trigger actions
              _buildSectionHeader('Diagnostics Commands'),
              GlassButton(
                label: 'Test Location Service Wrapper',
                isExpanded: true,
                onPressed: _isLoading ? null : _runSingleAttemptTest,
              ),
              const SizedBox(height: 8),
              GlassButton(
                label: 'Test Raw Geolocator Query',
                isExpanded: true,
                onPressed: _isLoading ? null : _runRawGeolocatorTest,
              ),
              const SizedBox(height: 8),
              GlassButton(
                label: _isStreaming ? 'Stop Stream Listener' : 'Start Stream Listener',
                isExpanded: true,
                variant: _isStreaming ? GlassButtonVariant.danger : GlassButtonVariant.secondary,
                onPressed: _togglePositionStream,
              ),
              const SizedBox(height: 16),

              // Status Loading or Error Output
              if (_isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: SasColors.accentEmerald),
                  ),
                ),
              ],

              if (_errorMessage != null) ...[
                _buildSectionHeader('Telemetry Error Output'),
                GlassCard(
                  borderColor: SasColors.danger.withValues(alpha: 0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: SasColors.danger,
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Acquired Position details
              if (_acquiredPosition != null) ...[
                _buildSectionHeader('Single Query Results'),
                GlassCard(
                  borderColor: SasColors.success.withValues(alpha: 0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResultRow('Test Route', _testType),
                        _buildResultRow('Execution Time', _durationMs),
                        const Divider(color: SasColors.glassBorder),
                        _buildResultRow('Latitude', _acquiredPosition!.latitude.toString()),
                        _buildResultRow('Longitude', _acquiredPosition!.longitude.toString()),
                        _buildResultRow('Accuracy', '${_acquiredPosition!.accuracy.toStringAsFixed(1)} meters'),
                        _buildResultRow('Mocked (Fake)', _acquiredPosition!.isMocked ? 'YES (BLOCKED)' : 'NO'),
                        _buildResultRow('Timestamp', _acquiredPosition!.timestamp.toString()),
                        _buildResultRow('Altitude', '${_acquiredPosition!.altitude.toStringAsFixed(1)}m'),
                        _buildResultRow('Speed', '${_acquiredPosition!.speed.toStringAsFixed(1)}m/s'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Stream history details
              if (_isStreaming || _streamedPositions.isNotEmpty) ...[
                _buildSectionHeader('Real-time Stream History (Max 10)'),
                if (_streamedPositions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Listening for updates...', style: TextStyle(color: SasColors.textMuted)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _streamedPositions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final pos = _streamedPositions[index];
                      return GlassCard(
                        child: ListTile(
                          dense: true,
                          title: Text(
                            'Update #${_streamedPositions.length - index} — ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          subtitle: Text(
                            'Accuracy: ${pos.accuracy.toStringAsFixed(1)}m | Mocked: ${pos.isMocked ? 'Yes' : 'No'}',
                            style: const TextStyle(color: SasColors.textMuted),
                          ),
                          trailing: Text(
                            '${pos.timestamp.hour.toString().padLeft(2, '0')}:${pos.timestamp.minute.toString().padLeft(2, '0')}:${pos.timestamp.second.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 10, color: SasColors.textMuted),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: SasColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value, required Color valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: SasColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: SasColors.textMuted, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
