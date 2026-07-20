import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/main_nav_screen.dart';
import 'screens/employee_placeholder_screen.dart';
import 'screens/receptionist/receptionist_main_nav_screen.dart';
import 'screens/therapist/therapist_main_nav_screen.dart';

void main() {
  runApp(const MapaladApp());
}

class MapaladApp extends StatelessWidget {
  const MapaladApp({super.key});

  Future<Widget> _resolveStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    if (token == null || token.isEmpty) {
      return const LoginScreen();
    }

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapalad Massage Spa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: FutureBuilder<Widget>(
        future: _resolveStartScreen(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(backgroundColor: AppColors.offWhite);
          }
          return SplashScreen(nextScreen: snapshot.data!);
        },
      ),
    );
  }
}