import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../lib/firestore_rest_service.dart';
import '../lib/utils/jwt_utils.dart';
import '../lib/identity_toolkit_service.dart';

Future<Response> onRequest(RequestContext context) async {
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
    return Response.json(statusCode: 401, body: {'success': false, 'message': 'Invalid or expired token'});
  }

  final userId = payload['userId'] as String?;
  if (userId == null) {
    return Response.json(statusCode: 401, body: {'success': false, 'message': 'Invalid token payload'});
  }

  if (context.request.method == HttpMethod.get) {
    final userDoc = await FirestoreRestService.getDocument('users', userId);
    if (userDoc == null) {
      return Response.json(statusCode: 404, body: {'success': false, 'message': 'User not found'});
    }

    return Response.json(body: {
      'success': true,
      'fullName': userDoc['fullName'],
      'email': userDoc['email'],
      'profilePicture': userDoc['profilePicture'],
      'role': userDoc['role'],
    });
  }

  if (context.request.method == HttpMethod.patch) {
    final userDoc = await FirestoreRestService.getDocument('users', userId);
    if (userDoc == null) {
      return Response.json(statusCode: 404, body: {'success': false, 'message': 'User not found'});
    }

    final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
    final updates = <String, dynamic>{};

    if (body.containsKey('fullName')) {
      final fullName = body['fullName'] as String?;
      if (fullName == null || fullName.trim().isEmpty) {
        return Response.json(statusCode: 400, body: {'success': false, 'message': 'Full name cannot be empty'});
      }
      updates['fullName'] = fullName.trim();
    }

    if (body.containsKey('profilePicture')) {
      final profilePicture = body['profilePicture'] as String?;
      if (profilePicture != null) {
        updates['profilePicture'] = profilePicture;
      }
    }

    if (body.containsKey('email')) {
      final newEmail = body['email'] as String?;
      final verificationToken = body['verificationToken'] as String?;

      if (newEmail == null || verificationToken == null) {
        return Response.json(statusCode: 400, body: {'success': false, 'message': 'Missing email or verificationToken'});
      }

      final tokenPayload = JwtUtils.verifyToken(verificationToken);
      if (tokenPayload == null ||
          tokenPayload['purpose'] != 'change_email_new_verified' ||
          tokenPayload['userId'] != userId ||
          tokenPayload['newEmail'] != newEmail) {
        return Response.json(statusCode: 401, body: {'success': false, 'message': 'Please verify the OTP sent to your new email again'});
      }

      try {
        await IdentityToolkitService.adminUpdateEmail(userId, newEmail);
      } catch (e) {
        return Response.json(statusCode: 500, body: {'success': false, 'message': 'Failed to update email in Firebase Auth'});
      }

      updates['email'] = newEmail;
    }

    if (updates.isEmpty) {
      return Response.json(statusCode: 400, body: {'success': false, 'message': 'Nothing to update'});
    }

    await FirestoreRestService.updateDocument('users', userId, updates);

    return Response.json(body: {'success': true, 'message': 'Profile updated'});
  }

  return Response(statusCode: 405, body: 'Method not allowed');
}