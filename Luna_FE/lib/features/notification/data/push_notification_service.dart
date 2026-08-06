import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoint.dart';

class PushNotificationService {
  final ApiClient _apiClient;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  PushNotificationService(this._apiClient);

  Future<void> initialize() async {
    try {
      // 1. Request permissions for iOS and Android
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted push notification permission');
        
        // 2. Get the initial token
        final token = await _messaging.getToken();
        if (token != null) {
          await _updateTokenOnServer(token);
        }

        // 3. Listen for token refreshes
        _messaging.onTokenRefresh.listen((newToken) {
          _updateTokenOnServer(newToken);
        });
      } else {
        debugPrint('User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging: $e');
    }
  }

  Future<void> _updateTokenOnServer(String token) async {
    try {
      await _apiClient.post(
        ApiEndpoint.devicePushToken,
        data: {'fcmToken': token},
        decode: (value) => null,
      );
      debugPrint('Successfully updated FCM token on server');
    } catch (e) {
      debugPrint('Failed to update FCM token on server: $e');
    }
  }
}
