import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../../lib/identity_toolkit_service.dart';
import '../../lib/utils/jwt_utils.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final authHeader = context.request.headers['authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return Response.json(statusCode: 401, body: {'success': false, 'message': 'Missing or invalid Authorization header'});
  }
  final payload = JwtUtils.verifyToken(authHeader.substring(7));
  if (payload == null) {
    return Response.json(statusCode: 401, body: {'success': false, 'message': 'Invalid or expired token'});
  }
  final userId = payload['userId'] as String?;
  if (userId == null) {
    return Response.json(statusCode: 401, body: {'success': false, 'message': 'Invalid token payload'});
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final newPassword = body['newPassword'] as String?;
  final verificationToken = body['verificationToken'] as String?;

  if (newPassword == null || newPassword.length < 6) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'Password must be at least 6 characters'});
  }
  if (verificationToken == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'Missing verificationToken'});
  }

  final tokenPayload = JwtUtils.verifyToken(verificationToken);
  if (tokenPayload == null ||
      tokenPayload['purpose'] != 'change_password_verified' ||
      tokenPayload['userId'] != userId) {
    return Response.json(statusCode: 401, body: {'success': false, 'message': 'Please verify OTP again before setting a new password'});
  }

  try {
    await IdentityToolkitService.adminSetPassword(userId, newPassword);
  } catch (e) {
    return Response.json(statusCode: 500, body: {'success': false, 'message': 'Failed to update password'});
  }

  return Response.json(body: {'success': true, 'message': 'Password has been updated'});
}