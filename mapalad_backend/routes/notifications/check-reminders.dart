import 'package:dart_frog/dart_frog.dart';
import '../../lib/firestore_rest_service.dart';
import '../../lib/notification_service.dart';
import '../../lib/utils/jwt_utils.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final authHeader = context.request.headers['authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Missing or invalid Authorization header'},
    );
  }

  final token = authHeader.substring(7);
  final payload = JwtUtils.verifyToken(token);
  if (payload == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Missing or invalid Authorization header'},
    );
  }

  final userId = payload['userId'] as String?;
  if (userId == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Missing or invalid Authorization header'},
    );
  }

  final bookings = await FirestoreRestService.queryWhereEquals('bookings', 'userId', userId);
  final now = DateTime.now();

  for (final booking in bookings) {
    if (booking['status'] != 'confirmed') continue;

    final appointmentDate = booking['appointmentDate'] as String?;
    final timeSlot = booking['timeSlot'] as String?;
    if (appointmentDate == null || timeSlot == null) continue;

    final startTime = _parseAppointmentStart(appointmentDate, timeSlot);
    if (startTime == null) continue;

    final hoursUntil = startTime.difference(now).inMinutes / 60.0;
    if (hoursUntil <= 0) continue;

    final bookingId = booking['id'] as String;
    final existing = await FirestoreRestService.queryWhereEquals('notifications', 'bookingId', bookingId);
    final existingTypes = existing.map((n) => n['type'] as String?).toSet();

    final serviceName = booking['serviceName'] as String? ?? 'Your service';

    if (hoursUntil <= 8 && !existingTypes.contains('reminder_8hr')) {
      await NotificationService.create(
        recipientId: userId,
        recipientRole: 'customer',
        bookingId: bookingId,
        type: 'reminder_8hr',
        title: 'Appointment Reminder',
        message: '$serviceName is less than 8 hours away.',
      );
    } else if (hoursUntil <= 24 && !existingTypes.contains('reminder_1day')) {
      await NotificationService.create(
        recipientId: userId,
        recipientRole: 'customer',
        bookingId: bookingId,
        type: 'reminder_1day',
        title: 'Appointment Reminder',
        message: '$serviceName is less than a day away.',
      );
    }
  }

  return Response.json(body: {'success': true});
}

DateTime? _parseAppointmentStart(String dateStr, String timeSlot) {
  try {
    final datePart = DateTime.parse(dateStr);
    final startStr = timeSlot.split('-').first.trim();
    final parts = startStr.split(' ');
    if (parts.length != 2) return null;
    final hm = parts[0].split(':');
    int hour = int.parse(hm[0]);
    final minute = int.parse(hm[1]);
    final meridiem = parts[1].toUpperCase();
    if (meridiem == 'PM' && hour != 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    return DateTime(datePart.year, datePart.month, datePart.day, hour, minute);
  } catch (_) {
    return null;
  }
}