import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import 'login_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String purpose; // 'forgot_password' or 'google_signup'
  final void Function(String verificationToken) onVerified;

  const OtpScreen({
    super.key,
    required this.email,
    required this.purpose,
    required this.onVerified,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showError('Enter the 6-digit code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$kApiBaseUrl/forgot-password/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'otp': otp, 'purpose': widget.purpose}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        widget.onVerified(data['verificationToken']);
      } else {
        _showError(data['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      _showError('Could not connect to server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      if (widget.purpose == 'forgot_password') {
        await http.post(
          Uri.parse('$kApiBaseUrl/forgot-password/request-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': widget.email}),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A new code was sent to your email')));
    } catch (_) {}
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.darkBrown),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 52,
      textStyle: TextStyle(fontSize: 20, color: AppColors.darkBrown, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(12)),
    );

    return AuthScaffold(
      title: 'Verify OTP',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Enter the 6-digit code sent to\n${widget.email}',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.brown, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Pinput(
            length: 6,
            controller: _otpController,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(border: Border.all(color: AppColors.brown, width: 2)),
            ),
          ),
          const SizedBox(height: 14),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _verifyOtp, child: const Text('Verify'))),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _resendOtp,
            child: Text("Didn't receive a code? Resend", style: TextStyle(color: AppColors.lightBrown)),
          ),
        ],
      ),
    );
  }
}