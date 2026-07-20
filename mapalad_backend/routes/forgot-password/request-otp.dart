import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../../lib/identity_toolkit_service.dart';
import '../../lib/firestore_rest_service.dart';
import '../../lib/utils/otp_utils.dart';
import '../../lib/email_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final email = body['email'] as String?;
  if (email == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'Missing email'});
  }

  final uid = await IdentityToolkitService.adminLookupUidByEmail(email);
  if (uid == null) {
    return Response.json(statusCode: 404, body: {'success': false, 'message': 'No account found with that email'});
  }

  final otp = OtpUtils.generate();
  await FirestoreRestService.addDocument('otp_codes', {
    'email': email,
    'otpCode': otp,
    'purpose': 'forgot_password',
    'isUsed': false,
    'expiresAt': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
    'createdAt': DateTime.now().toIso8601String(),
  });

  final sent = await EmailService.sendOtp(email, otp);
  if (!sent) {
    return Response.json(statusCode: 500, body: {'success': false, 'message': 'Failed to send email'});
  }

  return Response.json(body: {'success': true, 'message': 'OTP sent to your email'});
}