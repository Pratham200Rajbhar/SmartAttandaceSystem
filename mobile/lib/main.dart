// Application entry point.
// Initializes Hive, starts offline sync, registers FCM, and bootstraps the router.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/app/router.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/data/api/student_api.dart';
import 'package:smart_attendance_app/data/local/hive_service.dart';
import 'package:smart_attendance_app/data/local/offline_sync_service.dart';
import 'package:smart_attendance_app/data/local/notification_service.dart';
import 'package:smart_attendance_app/utils/logger.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level background message handler for FCM.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.addNotification(
    title: message.notification?.title ?? 'Notification',
    body: message.notification?.body ?? '',
    severity: _inferSeverity(message.data),
    source: 'push',
  );
}

/// Infers notification severity from FCM data payload.
String _inferSeverity(Map<String, dynamic> data) {
  final type = data['type'] as String?;
  if (type == 'low_attendance' || type == 'anomaly') return 'danger';
  if (type == 'warning') return 'warning';
  return 'info';
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final hiveService = HiveService();
      await hiveService.initialize();
      
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Minimal container for sync without full Riverpod scope
      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(hiveService),
          notificationServiceProvider.overrideWithValue(notificationService),
        ],
      );
      
      final syncService = container.read(offlineSyncServiceProvider);
      await syncService.syncQueue();
      return Future.value(true);
    } catch (e) {
      debugPrint("Workmanager failed: $e");
      return Future.value(false);
    }
  });
}

Future<void> main() async {
  // Catch unhandled async errors to prevent silent crashes
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Global Flutter framework error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      AppLogger.error(
        'Uncaught Flutter framework error: ${details.exception}',
        context: {'stack': details.stack?.toString()},
      );
      if (kReleaseMode) {
        // In release mode, log to a service instead of crashing
        Zone.current.handleUncaughtError(
          details.exception,
          details.stack ?? StackTrace.current,
        );
      }
    };

    // Lock to portrait for consistent camera/GPS UX
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Transparent status bar for glass aesthetic
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Initialize Hive before runApp
    final hiveService = HiveService();
    await hiveService.initialize();

    final notificationService = NotificationService();
    await notificationService.initialize();

    // Initialize Firebase (wrapped in try-catch in case google-services.json is missing)
    try {
      await Firebase.initializeApp();
      // Register background handler before any foreground setup
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      // Request permission
      await FirebaseMessaging.instance.requestPermission();
    } catch (e) {
      debugPrint("Firebase init failed: $e");
    }

    Workmanager().initialize(
      callbackDispatcher,
    );
    Workmanager().registerPeriodicTask(
      "offline-sync-task",
      "syncQueue",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    runApp(
      ProviderScope(
        overrides: [
          hiveServiceProvider.overrideWithValue(hiveService),
          notificationServiceProvider.overrideWithValue(notificationService),
        ],
        child: const SmartAttendanceApp(),
      ),
    );
  }, (error, stackTrace) {
    // Catch-all for unhandled async errors — prevents silent drops
    debugPrint('Unhandled error: $error');
    debugPrint('Stack trace: $stackTrace');
    AppLogger.error(
      'Unhandled zoned error: $error',
      context: {'stack': stackTrace.toString()},
    );
  });
}

class SmartAttendanceApp extends ConsumerStatefulWidget {
  const SmartAttendanceApp({super.key});

  @override
  ConsumerState<SmartAttendanceApp> createState() => _SmartAttendanceAppState();
}

class _SmartAttendanceAppState extends ConsumerState<SmartAttendanceApp> {
  @override
  void initState() {
    super.initState();
    // Start background offline sync listener
    ref.read(offlineSyncServiceProvider).startListening();
    // Set up FCM foreground handler and token registration
    _initializeFcm();
  }

  /// Registers the FCM token with the backend and sets up the foreground
  /// message handler to write incoming push messages into the local store.
  Future<void> _initializeFcm() async {
    try {
      // Get and register the FCM token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        try {
          await ref.read(studentApiProvider).registerFcmToken(token);
        } catch (e) {
          // Endpoint may not exist yet — log and continue
          debugPrint('FCM token registration failed (endpoint may not exist): $e');
        }
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await ref.read(studentApiProvider).registerFcmToken(newToken);
        } catch (e) {
          debugPrint('FCM token refresh registration failed: $e');
        }
      });

      // Foreground message handler — writes to Hive notification store
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final notifService = ref.read(notificationServiceProvider);
        await notifService.addNotification(
          title: message.notification?.title ?? 'Notification',
          body: message.notification?.body ?? '',
          severity: _inferSeverity(message.data),
          source: 'push',
        );
        // Trigger notifications provider reload for live badge update
        await ref.read(notificationsProvider.notifier).load();
      });
    } catch (e) {
      debugPrint('FCM initialization failed: $e');
    }
  }

  @override
  void dispose() {
    ref.read(offlineSyncServiceProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Smart Attendance',
      debugShowCheckedModeBanner: false,
      theme: buildSasTheme(),
      routerConfig: router,
    );
  }
}
