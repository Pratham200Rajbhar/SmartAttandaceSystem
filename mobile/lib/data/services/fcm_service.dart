// Firebase Cloud Messaging service
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 FCM Background Message: ${message.notification?.title}');
}

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM
  Future<String?> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ FCM: User granted permission');
    } else {
      debugPrint('❌ FCM: User declined permission');
      return null;
    }

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      debugPrint('📱 FCM Token: $token');
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('📱 FCM Token refreshed: $newToken');
      // TODO: Send new token to backend
    });

    return token;
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // Create notification channel (Android)
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 FCM Foreground Message: ${message.notification?.title}');
    
    // Show local notification
    _showLocalNotification(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    
    // Navigate based on notification type
    final type = message.data['type'];
    switch (type) {
      case 'attendance_marked':
        // Navigate to history screen
        debugPrint('Navigate to history');
        break;
      case 'leave_approved':
      case 'leave_rejected':
        // Navigate to leave history
        debugPrint('Navigate to leave history');
        break;
      case 'at_risk_warning':
        // Navigate to analytics
        debugPrint('Navigate to analytics');
        break;
      case 'dispute_resolved':
        // Navigate to flagged detail
        debugPrint('Navigate to dispute');
        break;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: message.data.toString(),
    );
  }
}
