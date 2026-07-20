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
  final fullName = body['fullName'] as String?;
  final email = body['email'] as String?;
  final password = body['password'] as String?;
  final isEmployee = body['isEmployee'] as bool? ?? false;
  final employeeRole = body['employeeRole'] as String?; // 'receptionist' or 'therapist'

  if (fullName == null || email == null || password == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'Missing fields'});
  }

  if (isEmployee && (employeeRole == null || !['receptionist', 'therapist'].contains(employeeRole))) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'Please select a valid employee role'});
  }

  final role = isEmployee ? employeeRole! : 'customer';

  try {
    final existingUid = await IdentityToolkitService.adminLookupUidByEmail(email);
    if (existingUid != null) {
      return Response.json(statusCode: 409, body: {'success': false, 'message': 'Email already registered'});
    }

    final uid = await IdentityToolkitService.signUp(email, password);

    await FirestoreRestService.setDocument('users', uid, {
      'fullName': fullName,
      'email': email,
      'authProvider': 'local',
      'needsPassword': false,
      'role': role,
      'createdAt': DateTime.now().toIso8601String(),
    });

    final token = JwtUtils.generateToken(email, uid);

    return Response.json(body: {
      'success': true,
      'message': 'Account created',
      'token': token,
      'fullName': fullName,
      'role': role,
    });
  } on IdentityToolkitException catch (e) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': e.message});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'success': false, 'message': 'Signup failed: $e'});
  }
}