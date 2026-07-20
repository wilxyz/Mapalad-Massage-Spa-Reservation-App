import 'package:dart_frog/dart_frog.dart';
import '../../lib/firestore_rest_service.dart';
import '../../lib/utils/jwt_utils.dart';

const List<String> _kAllTimeSlots = [
  '11:00 AM - 12:00 PM',
  '12:00 PM - 1:00 PM',
  '1:00 PM - 2:00 PM',
  '2:00 PM - 3:00 PM',
  '3:00 PM - 4:00 PM',
  '4:00 PM - 5:00 PM',
  '5:00 PM - 6:00 PM',
  '6:00 PM - 7:00 PM',
  '7:00 PM - 8:00 PM',
  '8:00 PM - 9:00 PM',
  '9:00 PM - 10:00 PM',
  '10:00 PM - 11:00 PM',
];

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

  final date = context.request.uri.queryParameters['date'];
  if (date == null || date.isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Missing date query parameter'},
    );
  }

  final bookingDocs = await FirestoreRestService.queryWhereEquals('bookings', 'appointmentDate', date);

  final takenSlots = bookingDocs
      .where((b) => b['therapistId'] == userId && (b['status'] == 'pending' || b['status'] == 'confirmed'))
      .map((b) => b['timeSlot'] as String)
      .toSet()
      .toList();

  final availableSlots = _kAllTimeSlots.where((slot) => !takenSlots.contains(slot)).toList();

  return Response.json(body: {
    'success': true,
    'date': date,
    'schedule': {
      'therapistId': userId,
      'fullName': callerDoc['fullName'],
      'takenSlots': takenSlots,
      'availableSlots': availableSlots,
    },
  });
}