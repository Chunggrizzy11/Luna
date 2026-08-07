import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoint.dart';
import '../domain/notification_models.dart';

class NotificationRepository {
  const NotificationRepository(this._api);
  final ApiClient _api;

  /// Get notifications for current device.
  Future<NotificationListResponse> list({int page = 1, int limit = 20}) async {
    return (await _api.get<NotificationListResponse>(
      ApiEndpoint.notifications,
      queryParameters: {'page': page, 'limit': limit},
      decode: (value) => NotificationListResponse.fromJson(_map(value)),
    )).data;
  }

  /// Mark a notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _api.patch<void>(
      '${ApiEndpoint.notifications}/$notificationId/read',
      decode: (_) => null,
    );
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    await _api.patch<void>(
      '${ApiEndpoint.notifications}/read-all',
      decode: (_) => null,
    );
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw FormatException('Invalid notification response. Type was ${value.runtimeType}, value: $value');
  }
}