import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../../lib/firestore_rest_service.dart';
import '../../lib/utils/jwt_utils.dart';
import '../../lib/utils/otp_utils.dart';
import '../../lib/email_service.dart';

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
  final purpose = body['purpose'] as String?;
  if (purpose != 'change_email_current' && purpose != 'change_email_new' && purpose != 'change_password') {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'Invalid purpose'});
  }

  final userDoc = await FirestoreRestService.getDocument('users', userId);
  if (userDoc == null) {
    return Response.json(statusCode: 404, body: {'success': false, 'message': 'User not found'});
  }
  final currentEmail = userDoc['email'] as String?;

  String targetEmail;

  if (purpose == 'change_email_new') {
    final stepToken = body['verificationToken'] as String?;
    final newEmail = body['newEmail'] as String?;
    if (stepToken == null || newEmail == null) {
      return Response.json(statusCode: 400, body: {'success': false, 'message': 'Missing verificationToken or newEmail'});
    }
    final stepPayload = JwtUtils.verifyToken(stepToken);
    if (stepPayload == null ||
        stepPayload['purpose'] != 'change_email_current_verified' ||
        stepPayload['userId'] != userId) {
      return Response.json(statusCode: 401, body: {'success': false, 'message': 'Please re-verify your current email first'});
    }
    targetEmail = newEmail;
  } else {
    if (currentEmail == null) {
      return Response.json(statusCode: 400, body: {'success': false, 'message': 'No email on file for this account'});
    }
    targetEmail = currentEmail;
  }

  final otp = OtpUtils.generate();
  await FirestoreRestService.addDocument('otp_codes', {
    'email': targetEmail,
    'otpCode': otp,
    'purpose': purpose,
    'isUsed': false,
    'expiresAt': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
    'createdAt': DateTime.now().toIso8601String(),
  });

  final sent = await EmailService.sendOtp(targetEmail, otp);
  if (!sent) {
    return Response.json(statusCode: 500, body: {'success': false, 'message': 'Failed to send email'});
  }

  return Response.json(body: {'success': true, 'message': 'OTP sent', 'email': targetEmail});
}