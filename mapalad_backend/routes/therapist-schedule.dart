import 'package:dart_frog/dart_frog.dart';
import '../lib/firestore_rest_service.dart';

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

  final date = context.request.uri.queryParameters['date'];
  if (date == null || date.isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Missing date query parameter'},
    );
  }

  final therapistDocs = await FirestoreRestService.queryWhereEquals('users', 'role', 'therapist');
  final bookingDocs = await FirestoreRestService.queryWhereEquals('bookings', 'appointmentDate', date);

  final schedule = therapistDocs.map((therapist) {
    final therapistId = therapist['id'] as String;
    final takenSlots = bookingDocs
        .where((b) => b['therapistId'] == therapistId && (b['status'] == 'pending' || b['status'] == 'confirmed'))
        .map((b) => b['timeSlot'] as String)
        .toSet()
        .toList();

    final availableSlots = _kAllTimeSlots.where((slot) => !takenSlots.contains(slot)).toList();

    return {
      'therapistId': therapistId,
      'fullName': therapist['fullName'],
      'takenSlots': takenSlots,
      'availableSlots': availableSlots,
    };
  }).toList();

  return Response.json(body: {'success': true, 'date': date, 'schedule': schedule});
}