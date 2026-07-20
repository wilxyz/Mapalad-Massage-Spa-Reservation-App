import 'package:dart_frog/dart_frog.dart';
import '../lib/firestore_rest_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final docs = await FirestoreRestService.listDocuments('branches');
  final branches = docs.map((doc) => {
        'branchId': doc['id'],
        'branchName': doc['branchName'],
        'branchAddress': doc['branchAddress'],
      }).toList();

  return Response.json(body: {'success': true, 'branches': branches});
}