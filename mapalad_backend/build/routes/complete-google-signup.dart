import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../lib/identity_toolkit_service.dart';
import '../lib/firestore_rest_service.dart';
import '../lib/utils/jwt_utils.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final verificationToken = body['verificationToken'] as String?;
  final password = body['password'] as String?;
  final requestedRole = body['role'] as String?;

  if (verificationToken == null || password == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'Missing fields'});
  }

  final payload = JwtUtils.verifyToken(verificationToken);
  if (payload == null || payload['purpose'] != 'google_signup') {
    return Response.json(statusCode: 401, body: {'success': false, 'message': 'Invalid or expired verification token'});
  }

  final email = payload['email'] as String;

  final uid = await IdentityToolkitService.adminLookupUidByEmail(email);
  if (uid == null) {
    return Response.json(statusCode: 404, body: {'success': false, 'message': 'User not found'});
  }

  await IdentityToolkitService.adminSetPassword(uid, password);

  const validRoles = {'customer', 'receptionist', 'therapist'};
  final updates = <String, dynamic>{'needsPassword': false};
  if (requestedRole != null && validRoles.contains(requestedRole)) {
    updates['role'] = requestedRole;
  }
  await FirestoreRestService.updateDocument('users', uid, updates);

  final userDoc = await FirestoreRestService.getDocument('users', uid);
  final fullName = (userDoc?['fullName'] as String?) ?? 'User';
  final role = (userDoc?['role'] as String?) ?? 'customer';

  final token = JwtUtils.generateToken(email, uid);

  return Response.json(body: {
    'success': true,
    'message': 'Account setup complete',
    'token': token,
    'fullName': fullName,
    'role': role,
  });
}