import 'package:dart_frog/dart_frog.dart';
import '../lib/firestore_rest_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final docs = await FirestoreRestService.queryWhereEquals('users', 'role', 'therapist');
  final therapists = docs.map((doc) => {
        'uid': doc['id'],
        'fullName': doc['fullName'],
      }).toList();

  return Response.json(body: {'success': true, 'therapists': therapists});
}