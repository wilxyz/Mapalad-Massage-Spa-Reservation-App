import 'package:dart_frog/dart_frog.dart';
import '../../lib/firestore_rest_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final params = context.request.uri.queryParameters;
  final branchId = params['branchId'];
  final date = params['date'];
  final therapistId = params['therapistId'];

  if (branchId == null || date == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'branchId and date are required'});
  }

  final docs = await FirestoreRestService.queryWhereEquals('bookings', 'branchId', branchId);

  final takenSlots = docs
      .where((doc) =>
          doc['appointmentDate'] == date &&
          (therapistId == null || doc['therapistId'] == therapistId) &&
          doc['status'] != 'cancelled')
      .map((doc) => doc['timeSlot'] as String)
      .toList();

  return Response.json(body: {'success': true, 'takenSlots': takenSlots});
}