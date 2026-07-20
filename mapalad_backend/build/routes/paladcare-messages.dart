import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../lib/firestore_rest_service.dart';
import '../lib/utils/jwt_utils.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    return _saveMessage(context);
  }
  if (context.request.method == HttpMethod.get) {
    return _listMessages(context);
  }
  return Response(statusCode: 405, body: 'Method not allowed');
}

Future<String?> _requireUserId(RequestContext context) async {
  final authHeader = context.request.headers['authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) return null;
  final token = authHeader.substring(7);
  final payload = JwtUtils.verifyToken(token);
  if (payload == null) return null;
  return payload['userId'] as String?;
}

Future<Response> _saveMessage(RequestContext context) async {
  final userId = await _requireUserId(context);
  if (userId == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Missing or invalid Authorization header'},
    );
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final sender = body['sender'] as String?;
  final message = body['message'] as String?;

  if (sender != 'user' && sender != 'bot') {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Invalid sender value'},
    );
  }
  if (message == null || message.isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Message cannot be empty'},
    );
  }

  final messageData = {
    'userId': userId,
    'sender': sender,
    'message': message,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };

  String messageId;
  try {
    messageId = await FirestoreRestService.addDocument('paladcare_messages', messageData);
    print('PaladCare: wrote message $messageId for user $userId'); // TEMP DEBUG
  } catch (e, st) {
    print('PaladCare: addDocument FAILED: $e'); // TEMP DEBUG
    print(st); // TEMP DEBUG
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Failed to save message: $e'},
    );
  }

  return Response.json(body: {'success': true, 'messageId': messageId});
}

Future<Response> _listMessages(RequestContext context) async {
  final userId = await _requireUserId(context);
  if (userId == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Missing or invalid Authorization header'},
    );
  }

  final docs = await FirestoreRestService.queryWhereEquals('paladcare_messages', 'userId', userId);

  final messages = docs.map((doc) => {
        'messageId': doc['id'],
        'sender': doc['sender'],
        'message': doc['message'],
        'createdAt': doc['createdAt'],
      }).toList();

  messages.sort((a, b) => (a['createdAt'] as String).compareTo(b['createdAt'] as String));

  return Response.json(body: {'success': true, 'messages': messages});
}