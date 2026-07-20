import 'package:dart_frog/dart_frog.dart';
import '../../lib/firestore_rest_service.dart';
import '../../lib/utils/jwt_utils.dart';

String _formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
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
      body: {'success': false, 'message': 'Invalid or expired token'},
    );
  }

  final userId = payload['userId'] as String?;
  if (userId == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Invalid token payload'},
    );
  }

  final callerDoc = await FirestoreRestService.getDocument('users', userId);
  if (callerDoc == null || callerDoc['role'] != 'therapist') {
    return Response.json(
      statusCode: 403,
      body: {'success': false, 'message': 'Therapist access only'},
    );
  }

  final now = DateTime.now();
  final todayStr = _formatDate(now);

  final requestedDate = context.request.uri.queryParameters['date'];
  final filterDate = (requestedDate == null || requestedDate.isEmpty) ? todayStr : requestedDate;

  // Same date-scoped query pattern as therapist-schedule.dart, then filtered
  // in-memory to just this caller's own assigned bookings.
  final bookingDocs = await FirestoreRestService.queryWhereEquals('bookings', 'appointmentDate', filterDate);

  final myBookings = bookingDocs.where((booking) {
    return booking['therapistId'] == userId;
  }).toList()
    ..sort((a, b) => (a['createdAt'] as String? ?? '').compareTo(b['createdAt'] as String? ?? ''));

  final bookingsJson = myBookings.map((booking) {
    final map = Map<String, dynamic>.from(booking);
    final id = map.remove('id');
    return {'bookingId': id, ...map};
  }).toList();

  return Response.json(body: {
    'success': true,
    'filterDate': filterDate,
    'bookings': bookingsJson,
  });
}