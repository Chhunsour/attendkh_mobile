import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Ignore initialization errors in background if options are missing
  }
  AppLogger.d("Handling a background message: ${message.messageId}");

  // If the message already contains a notification payload, Firebase SDK handles
  // native system notification display on Android/iOS in background. Skip manual local notification to avoid duplicate popup.
  if (message.notification != null) {
    return;
  }

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
            color: Color(0xFF0052FF),
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
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
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

      // Enable foreground notification banners on iOS & Android
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.i('Got a message whilst in the foreground!');
        AppLogger.i('Message data: ${message.data}');

        if (message.notification != null) {
          AppLogger.i(
            'Message also contained a notification: ${message.notification?.title} - ${message.notification?.body}',
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
          AppLogger.i(
            'App launched from terminated state via notification tap',
          );
          handleNotificationDataRouting(message.data);
        }
      });

      _initialized = true;
    } catch (e) {
      AppLogger.e('Failed to initialize Firebase Messaging: $e');
    }
  }

  Map<String, dynamic>? _pendingNotificationData;
  Map<String, dynamic>? get pendingNotificationData => _pendingNotificationData;

  void consumePendingNotification() {
    if (_pendingNotificationData != null) {
      final data = _pendingNotificationData!;
      _pendingNotificationData = null;
      handleNotificationDataRouting(data);
    }
  }

  void handleNotificationDataRouting(Map<String, dynamic> data) {
    if (rootNavigatorKey.currentContext == null) {
      _pendingNotificationData = data;
      return;
    }
    final context = rootNavigatorKey.currentContext!;

    // If still on splash or login, stash the notification to consume after navigation completes
    try {
      final currentRoute = GoRouter.of(context).routeInformationProvider.value.uri.toString();
      if (currentRoute == AppRoutes.splash || currentRoute == AppRoutes.login) {
        _pendingNotificationData = data;
        return;
      }
    } catch (_) {}

    AppLogger.i('Routing push notification payload: $data');

    // Extract type to determine deep link
    final String? type = data['type'];
    if (type == null) {
      context.push(AppRoutes.notifications);
      return;
    }

    // Deep link mapping
    switch (type) {
      case 'leave_request':
      case 'upcoming_leave':
        context.push(AppRoutes.leaveList);
        break;
      case 'overtime_request':
        context.push(AppRoutes.requestOvertime);
        break;
      case 'expense_claim':
        context.push(AppRoutes.expense);
        break;
      case 'attendance':
      case 'clock_in_reminder':
      case 'clock_out_reminder':
      case 'early_clock_in':
      case 'late_clock_in':
      case 'early_leave':
      case 'break_reminder':
      case 'overtime_reminder':
        context.push(AppRoutes.attendance);
        break;
      case 'payslip':
        context.push(AppRoutes.payslip);
        break;
      case 'training_reminder':
        context.push(AppRoutes.training);
        break;
      case 'upcoming_holiday':
        context.push(AppRoutes.employeeHolidays);
        break;
      default:
        context.push(AppRoutes.notifications);
        break;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    final notification = message.notification;
    final data = message.data;

    String? title = notification?.title ?? data['title'] ?? data['subject'];
    String? body =
        notification?.body ?? data['body'] ?? data['message'] ?? data['text'];

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
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // channel id
            'High Importance Notifications', // channel name
            channelDescription:
                'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF0052FF),
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(data),
      );
    }
  }

  /// Show a manual local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    if (kIsWeb) return;

    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel', // channel id
          'High Importance Notifications', // channel name
          channelDescription:
              'This channel is used for important notifications.',
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF0052FF),
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }

  /// Invalidates this device's push token on sign-out.
  ///
  /// The backend maps the token to the user who registered it, so without this
  /// a signed-out (or handed-over) device keeps receiving the previous user's
  /// leave/payslip notifications. Deleting the token client-side makes the
  /// stored one undeliverable; the next login syncs a fresh one.
  Future<void> clearToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      AppLogger.w('Failed to delete FCM token on logout: $e');
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

      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : const Color(0xFFDBEAFE),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: isDark ? const Color(0xFF93C5FD) : AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Enable Notifications',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.grey900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'It looks like notifications are disabled. Please enable them in your phone settings to receive important attendance and leave updates.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : const Color(0xFFE5E7EB),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.grey300
                              : const Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Open Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            color: Color(0xFF0052FF),
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
