import 'package:equatable/equatable.dart';

enum NotificationType {
  cycleReminder('Chu kỳ bắt đầu'),
  careSuggestion('Gợi ý chăm sóc'),
  journalPrompt('Nhắc nhở nhật ký'),
  pairingUpdate('Cập nhật ghép đôi'),
  general('Thông báo chung'),
  sos('Tín hiệu khẩn cấp');

  const NotificationType(this.title);
  final String title;
}

class Notification extends Equatable {
  const Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, String>? data;
  final bool read;
  final DateTime createdAt;

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name.toLowerCase() == json['type']?.toString().toLowerCase(),
        orElse: () => NotificationType.general,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      data: (json['data'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as String),
      ),
      read: json['read'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      if (data != null) 'data': data,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    body,
    data,
    read,
    createdAt,
  ];
}

class NotificationListResponse extends Equatable {
  const NotificationListResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.unreadCount,
  });

  final List<Notification> items;
  final int page;
  final int limit;
  final int unreadCount;

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      items: (json['items'] as List)
          .map((item) => Notification.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      limit: json['limit'] as int,
      unreadCount: json['unreadCount'] as int,
    );
  }

  @override
  List<Object?> get props => [items, page, limit, unreadCount];
}