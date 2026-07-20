import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import 'login_screen.dart';
import 'otp_screen.dart';
import 'create_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$kApiBaseUrl/forgot-password/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              email: email,
              purpose: 'forgot_password',
              onVerified: (verificationToken) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePasswordScreen(
                      verificationToken: verificationToken,
                      purpose: 'reset_password',
                    ),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        _showError(data['message'] ?? 'Could not send OTP');
      }
    } catch (e) {
      _showError('Could not connect to server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.darkBrown),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Forgot Password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter your email and we'll send you a 6-digit code to reset your password.",
            style: TextStyle(color: AppColors.brown, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text('Email:', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(controller: _emailController, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _sendOtp, child: const Text('Send Code')),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back to Login', style: TextStyle(color: AppColors.brown)),
            ),
          ),
        ],
      ),
    );
  }
}