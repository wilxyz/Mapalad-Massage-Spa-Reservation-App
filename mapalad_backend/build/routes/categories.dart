import 'package:dart_frog/dart_frog.dart';
import '../lib/firestore_rest_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final docs = await FirestoreRestService.listDocuments('categories');
  final categories = docs.map((doc) => {
        'categoryId': doc['id'],
        'categoryName': doc['categoryName'],
      }).toList();

  return Response.json(body: {'success': true, 'categories': categories});
}