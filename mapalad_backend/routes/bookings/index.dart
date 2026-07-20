import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../../lib/firestore_rest_service.dart';
import '../../lib/notification_service.dart';
import '../../lib/utils/jwt_utils.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    return _createBooking(context);
  }
  if (context.request.method == HttpMethod.get) {
    return _listMyBookings(context);
  }
  return Response(statusCode: 405, body: 'Method not allowed');
}

Future<String?> _requireUserId(RequestContext context) async {
  final authHeader = context.request.headers['authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) return null;
  final token = authHeader.substring(7);
  final payload = JwtUtils.verifyToken(token);
  if (payload == null) return null;
  return payload['userId'] as String?;
}

Future<Response> _createBooking(RequestContext context) async {
  final userId = await _requireUserId(context);
  if (userId == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Missing or invalid Authorization header'},
    );
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;

  final bookingData = {
    'userId': userId,
    'serviceId': body['serviceId'],
    'serviceName': body['serviceName'],
    'categoryName': body['categoryName'],
    'duration': body['duration'],
    'price': (body['price'] as num).toDouble(),
    'branchId': body['branchId'],
    'branchName': body['branchName'],
    'therapistId': body['therapistId'],
    'therapistName': body['therapistName'],
    'appointmentDate': body['appointmentDate'],
    'timeSlot': body['timeSlot'],
    'addOnId': body['addOnId'],
    'addOnName': body['addOnName'],
    'fullName': body['fullName'],
    'contactNumber': body['contactNumber'],
    'email': body['email'],
    'specialRequests': body['specialRequests'],
    'status': 'pending',
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };

  final bookingId = await FirestoreRestService.addDocument('bookings', bookingData);

  // --- NEW: notifications for the new booking ---
  final serviceName = body['serviceName'] as String? ?? 'A service';

  await NotificationService.create(
    recipientId: userId,
    recipientRole: 'customer',
    bookingId: bookingId,
    type: 'booking_submitted',
    title: 'Booking Submitted',
    message: 'Your booking for $serviceName has been submitted.',
  );

  await NotificationService.create(
    recipientId: null,
    recipientRole: 'receptionist',
    bookingId: bookingId,
    type: 'new_booking',
    title: 'New Booking!',
    message: 'A new appointment for $serviceName has been made.',
  );

  final chosenTherapistId = body['therapistId'] as String?;
  if (chosenTherapistId != null && chosenTherapistId.isNotEmpty) {
    await NotificationService.create(
      recipientId: chosenTherapistId,
      recipientRole: 'therapist',
      bookingId: bookingId,
      type: 'booking_assigned',
      title: 'New Booking Assigned',
      message: 'You have been assigned a new $serviceName booking.',
    );
  }
  // --- END NEW ---

  return Response.json(body: {'success': true, 'bookingId': bookingId});
}

Future<Response> _listMyBookings(RequestContext context) async {
  final userId = await _requireUserId(context);
  if (userId == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Missing or invalid Authorization header'},
    );
  }

  final docs = await FirestoreRestService.queryWhereEquals('bookings', 'userId', userId);

  final bookings = docs.map((doc) => {
        'bookingId': doc['id'],
        'serviceId': doc['serviceId'],
        'serviceName': doc['serviceName'],
        'categoryName': doc['categoryName'],
        'duration': doc['duration'],
        'price': (doc['price'] as num?)?.toDouble() ?? 0.0,
        'branchId': doc['branchId'],
        'branchName': doc['branchName'],
        'therapistId': doc['therapistId'],
        'therapistName': doc['therapistName'],
        'appointmentDate': doc['appointmentDate'],
        'timeSlot': doc['timeSlot'],
        'addOnId': doc['addOnId'],
        'addOnName': doc['addOnName'],
        'fullName': doc['fullName'],
        'contactNumber': doc['contactNumber'],
        'email': doc['email'],
        'specialRequests': doc['specialRequests'],
        'status': doc['status'],
        'createdAt': doc['createdAt'],
      }).toList();

  return Response.json(body: {'success': true, 'bookings': bookings});
}