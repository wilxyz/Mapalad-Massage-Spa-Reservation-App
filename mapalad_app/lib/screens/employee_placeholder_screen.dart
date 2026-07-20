import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class EmployeePlaceholderScreen extends StatelessWidget {
  const EmployeePlaceholderScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Employee Portal', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.bold, fontSize: 24)),
              const SizedBox(height: 8),
              Text('This section is under construction.', style: TextStyle(color: AppColors.brown, fontSize: 14)),
              const Spacer(),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: Icon(Icons.logout, color: AppColors.darkBrown),
                  label: Text('Log Out', style: TextStyle(color: AppColors.darkBrown)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    side: BorderSide(color: AppColors.lightBrown),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}