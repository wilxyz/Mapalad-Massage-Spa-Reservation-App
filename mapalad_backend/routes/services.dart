import 'package:dart_frog/dart_frog.dart';
import '../lib/firestore_rest_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final categoryId = context.request.uri.queryParameters['categoryId'];

  final docs = categoryId != null
      ? await FirestoreRestService.queryWhereEquals('services', 'categoryId', categoryId)
      : await FirestoreRestService.listDocuments('services');

  final services = docs.map((doc) => {
        'serviceId': doc['id'],
        'serviceName': doc['serviceName'],
        'price': (doc['price'] as num).toDouble(),
        'duration': doc['duration'],
        'categoryId': doc['categoryId'],
      }).toList();

  return Response.json(body: {'success': true, 'services': services});
}