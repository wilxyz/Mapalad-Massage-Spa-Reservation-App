import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../../lib/identity_toolkit_service.dart';
import '../../lib/firestore_rest_service.dart';
import '../../lib/utils/jwt_utils.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final verificationToken = body['verificationToken'] as String?;
  final newPassword = body['newPassword'] as String?;

  if (verificationToken == null || newPassword == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'Missing fields'});
  }

  final payload = JwtUtils.verifyToken(verificationToken);
  if (payload == null || payload['purpose'] != 'reset_password') {
    return Response.json(statusCode: 401, body: {'success': false, 'message': 'Invalid or expired token'});
  }

  final email = payload['email'] as String;

  final uid = await IdentityToolkitService.adminLookupUidByEmail(email);
  if (uid == null) {
    return Response.json(statusCode: 404, body: {'success': false, 'message': 'User not found'});
  }

  await IdentityToolkitService.adminSetPassword(uid, newPassword);
  await FirestoreRestService.updateDocument('users', uid, {'needsPassword': false});

  return Response.json(body: {'success': true, 'message': 'Password reset successful'});
}