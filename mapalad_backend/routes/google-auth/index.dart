import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import '../../lib/identity_toolkit_service.dart';
import '../../lib/firestore_rest_service.dart';
import '../../lib/utils/jwt_utils.dart';
import '../../lib/utils/otp_utils.dart';
import '../../lib/email_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final idToken = body['idToken'] as String?;
  if (idToken == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'Missing idToken'});
  }

  final googleResponse = await http.get(Uri.parse('https://oauth2.googleapis.com/tokeninfo?id_token=$idToken'));
  if (googleResponse.statusCode != 200) {
    return Response.json(statusCode: 401, body: {'success': false, 'message': 'Invalid Google token'});
  }

  final googleData = jsonDecode(googleResponse.body) as Map<String, dynamic>;
  final email = googleData['email'] as String?;
  final name = googleData['name'] as String? ?? email?.split('@').first ?? 'User';

  if (email == null) {
    return Response.json(statusCode: 401, body: {'success': false, 'message': 'Could not read Google account info'});
  }

  final existingUid = await IdentityToolkitService.adminLookupUidByEmail(email);

  if (existingUid != null) {
    final userDoc = await FirestoreRestService.getDocument('users', existingUid);
    final needsPassword = (userDoc?['needsPassword'] as bool?) ?? false;
    final role = (userDoc?['role'] as String?) ?? 'customer';

    if (!needsPassword) {
      final fullName = (userDoc?['fullName'] as String?) ?? name;
      final token = JwtUtils.generateToken(email, existingUid);
      return Response.json(body: {'success': true, 'isNewUser': false, 'token': token, 'fullName': fullName, 'role': role});
    }

    await _sendSignupOtp(email);
    return Response.json(body: {'success': true, 'isNewUser': true, 'email': email});
  }

  final newUid = await IdentityToolkitService.adminCreateUser(
    email: email,
    displayName: name,
    emailVerified: true,
  );

  await FirestoreRestService.setDocument('users', newUid, {
    'fullName': name,
    'email': email,
    'authProvider': 'google',
    'needsPassword': true,
    'role': 'customer',
    'createdAt': DateTime.now().toIso8601String(),
  });

  await _sendSignupOtp(email);
  return Response.json(body: {'success': true, 'isNewUser': true, 'email': email});
}

Future<void> _sendSignupOtp(String email) async {
  final otp = OtpUtils.generate();
  await FirestoreRestService.addDocument('otp_codes', {
    'email': email,
    'otpCode': otp,
    'purpose': 'google_signup',
    'isUsed': false,
    'expiresAt': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
    'createdAt': DateTime.now().toIso8601String(),
  });
  await EmailService.sendOtp(email, otp);
}