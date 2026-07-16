import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Ignore initialization errors in background if options are missing
  }
  AppLogger.d("Handling a background message: ${message.messageId}");
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final ApiRepository _api = ApiRepository();
  bool _initialized = false;
  
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _localNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> init() async {
    if (_initialized) return;

    try {
      // Try to initialize Firebase. Will fail if google-services config is missing.
      await Firebase.initializeApp();
      
      await _initLocalNotifications();

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.i('User granted FCM permission: ${settings.authorizationStatus}');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.i('Got a message whilst in the foreground!');
        AppLogger.i('Message data: ${message.data}');

        if (message.notification != null) {
          AppLogger.i('Message also contained a notification: ${message.notification}');
          _showLocalNotification(message);
        }
      });

      _initialized = true;
    } catch (e) {
      AppLogger.e('Failed to initialize Firebase Messaging: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // channel id
            'High Importance Notifications', // channel name
            channelDescription: 'This channel is used for important notifications.',
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  /// Fetches the FCM token and sends it to the backend to link to the logged-in user.
  Future<void> syncTokenWithBackend() async {
    if (!_initialized) return;

    try {
      String? token;
      
      if (Platform.isIOS) {
        // For Apple platforms, ensure the APNS token is available before making a request
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          token = await FirebaseMessaging.instance.getToken();
        }
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token != null) {
        AppLogger.i('FCM Token: $token');
        await _api.post('/fcm-token', data: {'fcm_token': token});
        AppLogger.i('Successfully synced FCM token to backend.');
      } else {
        AppLogger.w('Failed to get FCM token');
      }
    } catch (e) {
      AppLogger.e('Error syncing FCM token with backend: $e');
    }
  }
}
