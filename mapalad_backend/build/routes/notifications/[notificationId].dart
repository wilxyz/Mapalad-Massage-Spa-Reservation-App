import 'package:dart_frog/dart_frog.dart';
import '../../lib/firestore_rest_service.dart';
import '../../lib/utils/jwt_utils.dart';

Future<Response> onRequest(RequestContext context, String notificationId) async {
  if (context.request.method != HttpMethod.patch) {
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

  final notification = await FirestoreRestService.getDocument('notifications', notificationId);
  if (notification == null) {
    return Response.json(
      statusCode: 404,
      body: {'success': false, 'message': 'Notification not found'},
    );
  }

  final callerDoc = await FirestoreRestService.getDocument('users', userId);
  final callerRole = callerDoc?['role'] as String? ?? 'customer';

  final recipientId = notification['recipientId'] as String?;
  final recipientRole = notification['recipientRole'] as String?;

  final isOwnNotification = recipientId != null && recipientId == userId;
  final isReceptionistBroadcast =
      recipientId == null && recipientRole == 'receptionist' && callerRole == 'receptionist';

  if (!isOwnNotification && !isReceptionistBroadcast) {
    return Response.json(
      statusCode: 403,
      body: {'success': false, 'message': 'You do not have permission to modify this notification'},
    );
  }

  await FirestoreRestService.updateDocument('notifications', notificationId, {'isRead': true});

  return Response.json(body: {'success': true, 'notificationId': notificationId});
}