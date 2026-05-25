
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
  
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      AppLogger.error(
        'Uncaught Flutter framework error: ${details.exception}',
        context: {'stack': details.stack?.toString()},
      );
      if (kReleaseMode) {
        
        Zone.current.handleUncaughtError(
          details.exception,
          details.stack ?? StackTrace.current,
        );
      }
    };

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    final hiveService = HiveService();
    await hiveService.initialize();

    final notificationService = NotificationService();
    await notificationService.initialize();

    try {
      await Firebase.initializeApp();
      
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
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
    
    ref.read(offlineSyncServiceProvider).startListening();
    
    _initializeFcm();
  }

  Future<void> _initializeFcm() async {
    try {
      
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        try {
          await ref.read(studentApiProvider).registerFcmToken(token);
        } catch (e) {
          
          debugPrint('FCM token registration failed (endpoint may not exist): $e');
        }
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await ref.read(studentApiProvider).registerFcmToken(newToken);
        } catch (e) {
          debugPrint('FCM token refresh registration failed: $e');
        }
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final notifService = ref.read(notificationServiceProvider);
        await notifService.addNotification(
          title: message.notification?.title ?? 'Notification',
          body: message.notification?.body ?? '',
          severity: _inferSeverity(message.data),
          source: 'push',
        );
        
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
