import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // Use a Gmail App Password (not your normal Gmail password).
  // Setup steps are at the bottom of this guide.
  static const String _senderEmail = 'mapalad.spa@gmail.com';
  static const String _appPassword = 'misffgbfxqsmucdv';

  static Future<bool> sendOtp(String recipientEmail, String otp) async {
    final smtpServer = gmail(_senderEmail, _appPassword);

    final message = Message()
      ..from = const Address(_senderEmail, 'Mapalad Massage Spa Corporation')
      ..recipients.add(recipientEmail)
      ..subject = 'Your Mapalad Verification Code'
      ..html = '''
        <div style="font-family: sans-serif; color:#543310;">
          <h2>Mapalad Massage Spa Corporation</h2>
          <p>Your OTP verification code is:</p>
          <h1 style="letter-spacing:4px;">$otp</h1>
          <p>This code expires in 5 minutes. If you did not request this, ignore this email.</p>
        </div>
      ''';

    try {
      await send(message, smtpServer);
      return true;
    } catch (e) {
      print('Email send error: $e');
      return false;
    }
  }
}