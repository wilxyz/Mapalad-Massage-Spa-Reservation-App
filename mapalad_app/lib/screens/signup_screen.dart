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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isEmployee = false;
  String? _employeeRole; // 'receptionist' or 'therapist'

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match');
      return;
    }
    if (_isEmployee && _employeeRole == null) {
      _showError('Please select your employee role');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$kApiBaseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': name,
          'email': email,
          'password': password,
          'isEmployee': _isEmployee,
          'employeeRole': _employeeRole,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final role = data['role'] as String? ?? 'customer';
        await prefs.setString('token', data['token']);
        await prefs.setString('fullName', data['fullName']);
        await prefs.setString('role', role);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => _screenForRole(role)),
        );
      } else {
        _showError(data['message'] ?? 'Sign up failed');
      }
    } catch (e) {
      _showError('Could not connect to server. Is the backend running?');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.darkBrown),
    );
  }

  Widget _buildRoleOption(String label, String value) {
    final isSelected = _employeeRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _employeeRole = value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brown : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: AppColors.darkBrown, width: 1.5) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.darkBrown,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create Account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Full Name:', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(controller: _nameController),
          const SizedBox(height: 12),
          Text('Email:', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(controller: _emailController, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          Text('Password:', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Confirm Password:', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(controller: _confirmController, obscureText: _obscurePassword),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _isEmployee,
                  activeColor: AppColors.brown,
                  onChanged: (value) => setState(() {
                    _isEmployee = value ?? false;
                    if (!_isEmployee) _employeeRole = null;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Text('I am an employee', style: TextStyle(color: AppColors.darkBrown, fontSize: 13)),
            ],
          ),
          if (_isEmployee) ...[
            const SizedBox(height: 6),
            Text('Select your role:', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRoleOption('Receptionist', 'receptionist'),
                _buildRoleOption('Therapist', 'therapist'),
              ],
            ),
          ],
          const SizedBox(height: 14),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _signup, child: const Text('Sign Up')),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Already have an account? Login', style: TextStyle(color: AppColors.brown)),
            ),
          ),
        ],
      ),
    );
  }
}