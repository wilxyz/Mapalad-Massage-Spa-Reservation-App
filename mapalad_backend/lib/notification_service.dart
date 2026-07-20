import 'firestore_rest_service.dart';

class NotificationService {
  static Future<void> create({
    required String? recipientId,
    required String recipientRole,
    required String bookingId,
    required String type,
    required String title,
    required String message,
  }) async {
    await FirestoreRestService.addDocument('notifications', {
      'recipientId': recipientId,
      'recipientRole': recipientRole,
      'bookingId': bookingId,
      'type': type,
      'title': title,
      'message': message,
      'isRead': false,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
}