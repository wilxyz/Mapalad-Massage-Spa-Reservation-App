import 'package:flutter/material.dart';
import '../widgets/main_bottom_nav.dart';
import 'home_content_screen.dart';
import 'history_screen.dart';
import 'booking_screen.dart';
import 'paladcare_screen.dart';
import 'profile_screen.dart';
import 'book_appointment_flow.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  List<Widget> get _pages => [
        const HomeContentScreen(),
        const HistoryScreen(),
        const BookingScreen(),
        const PaladCareScreen(),
        ProfileScreen(onNavigateToTab: _navigateToTab),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: MainBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BookAppointmentFlow()));
            } else {
              setState(() => _currentIndex = index);
            }
          },
        ),
      ),
    );
  }
}