import 'package:dart_frog/dart_frog.dart';
import '../lib/firestore_rest_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final docs = await FirestoreRestService.listDocuments('add_ons');
  final addOns = docs.map((doc) => {
        'addOnId': doc['id'],
        'addOnName': doc['addOnName'],
        'price': (doc['price'] as num).toDouble(),
        'duration': doc['duration'],
      }).toList();

  return Response.json(body: {'success': true, 'addOns': addOns});
}