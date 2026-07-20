class NotificationModel {
  final String notificationId;
  final String? recipientId;
  final String recipientRole;
  final String bookingId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.recipientId,
    required this.recipientRole,
    required this.bookingId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] as String? ?? '',
      recipientId: json['recipientId'] as String?,
      recipientRole: json['recipientRole'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}