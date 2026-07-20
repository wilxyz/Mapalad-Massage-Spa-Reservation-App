import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../../lib/firestore_rest_service.dart';
import '../../lib/utils/jwt_utils.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final email = body['email'] as String?;
  final otp = body['otp'] as String?;
  final purpose = body['purpose'] as String?;

  if (email == null || otp == null || purpose == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'Missing fields'});
  }

  final matches = await FirestoreRestService.queryWhereEquals('otp_codes', 'email', email);

  final validDocs = matches.where((doc) {
    final matchesOtp = doc['otpCode'] == otp;
    final matchesPurpose = doc['purpose'] == purpose;
    final notUsed = doc['isUsed'] == false;
    final expiresAt = DateTime.tryParse(doc['expiresAt'] as String? ?? '');
    final notExpired = expiresAt != null && expiresAt.isAfter(DateTime.now());
    return matchesOtp && matchesPurpose && notUsed && notExpired;
  }).toList();

  if (validDocs.isEmpty) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'Invalid or expired OTP'});
  }

  await FirestoreRestService.updateDocument('otp_codes', validDocs.first['id'] as String, {'isUsed': true});

  final tokenPurpose = purpose == 'forgot_password' ? 'reset_password' : 'google_signup';
  final verificationToken = JwtUtils.generateVerificationToken(email, tokenPurpose);

  return Response.json(body: {
    'success': true,
    'message': 'OTP verified',
    'verificationToken': verificationToken,
  });
}