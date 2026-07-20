import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class JwtUtils {
  static const String _secret = 'x7Qp!k2fL9zR@wT4mN6vB8cY1sD3aG5hJ0eU';

  static String generateToken(String email, String userId) {
    final jwt = JWT({'email': email, 'userId': userId});
    return jwt.sign(SecretKey(_secret), expiresIn: const Duration(days: 7));
  }

  static String generateVerificationToken(String email, String purpose) {
    final jwt = JWT({'email': email, 'purpose': purpose});
    return jwt.sign(SecretKey(_secret), expiresIn: const Duration(minutes: 10));
  }

  static String generateProfileVerificationToken({
    required String userId,
    required String purpose,
    String? newEmail,
  }) {
    final jwt = JWT({
      'userId': userId,
      'purpose': purpose,
      if (newEmail != null) 'newEmail': newEmail,
    });
    return jwt.sign(SecretKey(_secret), expiresIn: const Duration(minutes: 10));
  }

  static Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secret));
      return jwt.payload as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}