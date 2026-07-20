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
  final email = body['email'] as String?;
  final password = body['password'] as String?;

  if (email == null || password == null) {
    return Response.json(statusCode: 400, body: {'success': false, 'message': 'Missing fields'});
  }

  try {
    final uid = await IdentityToolkitService.signInWithPassword(email, password);
    final userDoc = await FirestoreRestService.getDocument('users', uid);
    final fullName = (userDoc?['fullName'] as String?) ?? 'User';
    final role = (userDoc?['role'] as String?) ?? 'customer';

    final token = JwtUtils.generateToken(email, uid);

    return Response.json(body: {
      'success': true,
      'message': 'Login successful',
      'token': token,
      'fullName': fullName,
      'role': role,
    });
  } on IdentityToolkitException catch (e) {
    return Response.json(statusCode: 401, body: {'success': false, 'message': e.message});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'success': false, 'message': 'Login failed: $e'});
  }
}