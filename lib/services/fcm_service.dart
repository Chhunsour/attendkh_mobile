import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Ignore initialization errors in background if options are missing
  }
  AppLogger.d("Handling a background message: ${message.messageId}");

  if (!kIsWeb) {
    final data = message.data;
    String? title = message.notification?.title ?? data['title'];
    String? body =
        message.notification?.body ?? data['body'] ?? data['message'];

    if (title == null && data['data'] is String) {
      try {
        final innerData = jsonDecode(data['data']);
        title = innerData['title'] ?? innerData['subject'];
        body = innerData['body'] ?? innerData['message'];
      } catch (_) {}
    }

    if (title != null || body != null || data.isNotEmpty) {
      final localNotifications = FlutterLocalNotificationsPlugin();
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        ),
      );
      await localNotifications.initialize(initializationSettings);

      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          'high_importance_channel', // id
          'High Importance Notifications', // title
          description: 'This channel is used for important notifications.',
          importance: Importance.max,
        );
        await localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
      }

      await localNotifications.show(
        message.messageId?.hashCode ?? data.hashCode,
        title ?? 'New Notification',
        body ?? 'You have a new message',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            color: Color(0xFFF97316),
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }
}


class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final ApiRepository _api = ApiRepository();
  bool _initialized = false;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<RemoteMessage> _onMessageController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onMessageStream => _onMessageController.stream;

  Future<void> _initLocalNotifications() async {
    if (kIsWeb) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            handleNotificationDataRouting(data);
            return;
          } catch (_) {}
        }
        if (rootNavigatorKey.currentContext != null) {
          rootNavigatorKey.currentContext!.go(AppRoutes.notifications);
        }
      },
    );

    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description:
            'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> init() async {
    if (_initialized) return;

    try {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        // Ignore duplicate app initialization errors
      }

      await _initLocalNotifications();

      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      }

      // Request permissions
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (status.isDenied) {
          await Permission.notification.request();
        }
      }

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

      AppLogger.i(
        'User granted FCM permission: ${settings.authorizationStatus}',
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.i('Got a message whilst in the foreground!');
        AppLogger.i('Message data: ${message.data}');

        if (message.notification != null) {
          AppLogger.i(
            'Message also contained a notification: ${message.notification}',
          );
        }
        _showLocalNotification(message);
        _onMessageController.add(message);
      });

      // Handle message open app from background tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.i('App opened from background via notification tap');
        handleNotificationDataRouting(message.data);
      });

      // Handle message open app from terminated state tap
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          AppLogger.i('App launched from terminated state via notification tap');
          handleNotificationDataRouting(message.data);
        }
      });

      _initialized = true;
    } catch (e) {
      AppLogger.e('Failed to initialize Firebase Messaging: $e');
    }
  }

  void handleNotificationDataRouting(Map<String, dynamic> data) {
    if (rootNavigatorKey.currentContext == null) return;
    final context = rootNavigatorKey.currentContext!;

    AppLogger.i('Routing push notification payload: $data');
    context.push(AppRoutes.notifications);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    final notification = message.notification;
    final data = message.data;

    String? title = notification?.title ?? data['title'];
    String? body = notification?.body ?? data['body'] ?? data['message'];

    if (title == null && data['data'] is String) {
      try {
        final innerData = jsonDecode(data['data']);
        title = innerData['title'] ?? innerData['subject'];
        body = innerData['body'] ?? innerData['message'];
      } catch (_) {}
    }

    if (title != null || body != null || data.isNotEmpty) {
      await _localNotificationsPlugin.show(
        message.messageId?.hashCode ?? data.hashCode,
        title ?? 'New Notification',
        body ?? 'You have a new message',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // channel id
            'High Importance Notifications', // channel name
            channelDescription:
                'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFFF97316),
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(data),
      );
    }
  }

  /// Fetches the FCM token and sends it to the backend to link to the logged-in user.
  Future<void> syncTokenWithBackend() async {
    if (!_initialized) {
      await init();
    }

    try {
      String? token;

      if (!kIsWeb && Platform.isIOS) {
        // For Apple platforms, ensure the APNS token is available before making a request
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          // Sometimes it takes a little bit of time for the APNS token to be generated
          await Future<void>.delayed(const Duration(seconds: 3));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        }

        if (apnsToken != null) {
          token = await FirebaseMessaging.instance.getToken();
        } else {
          AppLogger.w(
            'APNS token is null, skipping FCM token fetch (expected on iOS Simulator)',
          );
          return;
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

  /// Checks if notification permission is denied and prompts the user to open settings.
  Future<void> checkAndPromptNotificationPermission(
    BuildContext context,
  ) async {
    if (kIsWeb) return;

    final status = await Permission.notification.status;

    // If the permission is denied or permanently denied, show the settings prompt.
    if (status.isDenied || status.isPermanentlyDenied) {
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'It looks like notifications are disabled. Please enable them in your phone settings to receive important updates.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Dismiss'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  /// Tests if local notifications are working by displaying a dummy notification.
  Future<void> testLocalNotification() async {
    if (kIsWeb) return;
    try {
      await _localNotificationsPlugin.show(
        99999,
        'Test Notification',
        'This is a local test notification. It works!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            color: Color(0xFFF97316),
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      AppLogger.i('Test notification triggered successfully.');
    } catch (e) {
      AppLogger.e('Failed to trigger test notification: $e');
    }
  }
}
