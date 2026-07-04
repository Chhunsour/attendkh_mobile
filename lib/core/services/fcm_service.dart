import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mpg_hr_mobile_app/core/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/core/network/api_repository.dart';

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

  Future<void> init() async {
    if (_initialized) return;

    try {
      // Try to initialize Firebase. Will fail if google-services config is missing.
      await Firebase.initializeApp();

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
          // Note: Local notifications can be triggered here if desired
        }
      });

      _initialized = true;
    } catch (e) {
      AppLogger.e('Failed to initialize Firebase Messaging: $e');
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
