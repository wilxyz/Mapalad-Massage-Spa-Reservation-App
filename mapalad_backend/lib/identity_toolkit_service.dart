import 'dart:convert';
import 'package:http/http.dart' as http;
import 'google_auth_service.dart';
import 'firebase_config.dart';

class IdentityToolkitException implements Exception {
  final String message;
  IdentityToolkitException(this.message);
  @override
  String toString() => message;
}

class IdentityToolkitService {
  // ---------- Public (API key) operations ----------

  static Future<String> signUp(String email, String password) async {
    final response = await http.post(
      Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${FirebaseConfig.webApiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw IdentityToolkitException(data['error']?['message'] ?? 'Sign up failed');
    }
    return data['localId'] as String;
  }

  static Future<String> signInWithPassword(String email, String password) async {
    final response = await http.post(
      Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FirebaseConfig.webApiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw IdentityToolkitException(data['error']?['message'] ?? 'Invalid email or password');
    }
    return data['localId'] as String;
  }

  // ---------- Admin (service account) operations ----------

  static Future<String?> adminLookupUidByEmail(String email) async {
    final client = await GoogleAuthService.getClient();
    final response = await client.post(
      Uri.parse('https://identitytoolkit.googleapis.com/v1/projects/${FirebaseConfig.projectId}/accounts:lookup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': [email]}),
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final users = data['users'] as List<dynamic>?;
    if (users == null || users.isEmpty) return null;
    return (users.first as Map<String, dynamic>)['localId'] as String;
  }

  static Future<String> adminCreateUser({
    required String email,
    String? password,
    String? displayName,
    bool emailVerified = false,
  }) async {
    final client = await GoogleAuthService.getClient();
    final response = await client.post(
      Uri.parse('https://identitytoolkit.googleapis.com/v1/projects/${FirebaseConfig.projectId}/accounts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        if (password != null) 'password': password,
        if (displayName != null) 'displayName': displayName,
        'emailVerified': emailVerified,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw IdentityToolkitException(data['error']?['message'] ?? 'Failed to create user');
    }
    return data['localId'] as String;
  }

  static Future<void> adminSetPassword(String uid, String newPassword) async {
    final client = await GoogleAuthService.getClient();
    final response = await client.post(
      Uri.parse('https://identitytoolkit.googleapis.com/v1/projects/${FirebaseConfig.projectId}/accounts:update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'localId': uid, 'password': newPassword}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw IdentityToolkitException(data['error']?['message'] ?? 'Failed to update password');
    }
  }

  static Future<void> adminUpdateEmail(String uid, String newEmail) async {
    final client = await GoogleAuthService.getClient();
    final response = await client.post(
      Uri.parse('https://identitytoolkit.googleapis.com/v1/projects/${FirebaseConfig.projectId}/accounts:update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'localId': uid, 'email': newEmail}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw IdentityToolkitException(data['error']?['message'] ?? 'Failed to update email');
    }
  }
}