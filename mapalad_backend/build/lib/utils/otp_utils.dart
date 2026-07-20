import 'dart:math';

class OtpUtils {
  static String generate() {
    final rand = Random.secure();
    final code = 100000 + rand.nextInt(900000);
    return code.toString();
  }
}