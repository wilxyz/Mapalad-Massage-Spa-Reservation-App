import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import 'login_screen.dart';
import 'main_nav_screen.dart';
import 'employee_placeholder_screen.dart';
import 'receptionist/receptionist_main_nav_screen.dart';
import 'therapist/therapist_main_nav_screen.dart';

Widget _screenForRole(String role) {
  switch (role) {
    case 'customer':
      return const MainNavScreen();
    case 'receptionist':
      return const ReceptionistMainNavScreen();
    case 'therapist':
      return const TherapistMainNavScreen();
    default:
      return const EmployeePlaceholderScreen();
  }
}

class CreatePasswordScreen extends StatefulWidget {
  final String verificationToken;
  final String purpose; // 'google_signup' or 'reset_password'
  final String? selectedRole; // 'customer', 'receptionist', or 'therapist' — only used when purpose == 'google_signup'

  const CreatePasswordScreen({
    super.key,
    required this.verificationToken,
    this.purpose = 'google_signup',
    this.selectedRole,
  });

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final isGoogle = widget.purpose == 'google_signup';
      final endpoint = isGoogle ? '/complete-google-signup' : '/forgot-password/reset-password';
      final bodyMap = isGoogle
          ? {
              'verificationToken': widget.verificationToken,
              'password': password,
              if (widget.selectedRole != null) 'role': widget.selectedRole,
            }
          : {'verificationToken': widget.verificationToken, 'newPassword': password};

      final response = await http.post(
        Uri.parse('$kApiBaseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        if (isGoogle && data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          final role = data['role'] as String? ?? 'customer';
          await prefs.setString('token', data['token']);
          await prefs.setString('fullName', data['fullName']);
          await prefs.setString('role', role);

          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => _screenForRole(role)),
            (route) => false,
          );
        } else {
        _showError(data['message'] ?? 'Something went wrong');
      }}
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
      title: 'Create Password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.purpose == 'google_signup'
                ? 'Set a password so you can also log in using your email.'
                : 'Set a new password for your account.',
            style: TextStyle(color: AppColors.brown, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text('New Password:', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Confirm Password:', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(controller: _confirmController, obscureText: _obscure),
          const SizedBox(height: 14),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _submit, child: const Text('Save Password')),
        ],
      ),
    );
  }
}