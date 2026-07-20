import 'package:dart_frog/dart_frog.dart';
import '../../lib/firestore_rest_service.dart';
import '../../lib/utils/jwt_utils.dart';

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
      body: {'success': false, 'message': 'Missing or invalid Authorization header'},
    );
  }

  final userId = payload['userId'] as String?;
  if (userId == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Missing or invalid Authorization header'},
    );
  }

  final callerDoc = await FirestoreRestService.getDocument('users', userId);
  final callerRole = callerDoc?['role'] as String? ?? 'customer';

  List<Map<String, dynamic>> docs;
  if (callerRole == 'receptionist') {
    docs = await FirestoreRestService.queryWhereEquals('notifications', 'recipientRole', 'receptionist');
  } else {
    docs = await FirestoreRestService.queryWhereEquals('notifications', 'recipientId', userId);
  }

  docs.sort((a, b) => (b['createdAt'] as String? ?? '').compareTo(a['createdAt'] as String? ?? ''));

  final notifications = docs.map((doc) => {
        'notificationId': doc['id'],
        'recipientId': doc['recipientId'],
        'recipientRole': doc['recipientRole'],
        'bookingId': doc['bookingId'],
        'type': doc['type'],
        'title': doc['title'],
        'message': doc['message'],
        'isRead': doc['isRead'] ?? false,
        'createdAt': doc['createdAt'],
      }).toList();

  return Response.json(body: {'success': true, 'notifications': notifications});
}