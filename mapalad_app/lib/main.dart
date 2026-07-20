import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MapaladApp());
}

class MapaladApp extends StatelessWidget {
  const MapaladApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapalad Massage Spa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: SplashScreen(nextScreen: const LoginScreen()),
    );
  }
}