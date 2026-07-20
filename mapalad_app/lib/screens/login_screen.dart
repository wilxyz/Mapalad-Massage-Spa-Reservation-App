import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'otp_screen.dart';
import 'create_password_screen.dart';
import 'main_nav_screen.dart';
import 'employee_placeholder_screen.dart';
import 'receptionist/receptionist_main_nav_screen.dart';
import 'therapist/therapist_main_nav_screen.dart';

const String kApiBaseUrl = 'https://mapalad-massage-spa-reservation-app.onrender.com';

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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '268365777292-rlrmjk7d1ok3brdgk5sv99kf2e5n443a.apps.googleusercontent.com',
  );

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in both fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$kApiBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
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
        _showError(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      _showError('Could not connect to server. Is the backend running?');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        _showError('Google sign-in failed to return a token');
        return;
      }

      final response = await http.post(
        Uri.parse('$kApiBaseUrl/google-auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['isNewUser'] == true) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                email: data['email'],
                purpose: 'google_signup',
                onVerified: (verificationToken) async {
                  final selectedRole = await _promptForRole();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePasswordScreen(
                        verificationToken: verificationToken,
                        selectedRole: selectedRole,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        } else {
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
        }
      } else {
        _showError(data['message'] ?? 'Google sign-in failed');
      }
    } catch (e) {
      _showError('Google sign-in error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _promptForRole() async {
    final isEmployee = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(
              'Are you a customer or an employee?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 18),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            actions: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.darkBrown,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Customer',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.brown,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Employee',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ) ??
        false;

    if (!isEmployee) return 'customer';

    final employeeRole = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Are you a receptionist or a therapist?',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext, 'receptionist'),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Receptionist',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext, 'therapist'),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.brown,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Therapist',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return employeeRole ?? 'receptionist';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.darkBrown),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome!',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
              child: Text('Change Password', style: TextStyle(color: AppColors.lightBrown, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 6),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _login, child: const Text('Login')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _loginWithGoogle,
            icon: Image.asset('assets/images/google_logo.png', height: 20),
            label: const Text('Sign in with Google'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              side: BorderSide(color: AppColors.lightBrown),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text("Don't have an account?", style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 12)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightBrown),
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}