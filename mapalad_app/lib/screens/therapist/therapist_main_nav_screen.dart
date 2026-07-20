import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'therapist_home_screen.dart';
import 'therapist_availability_screen.dart';
import 'therapist_profile_screen.dart';

class TherapistMainNavScreen extends StatefulWidget {
  const TherapistMainNavScreen({super.key});

  @override
  State<TherapistMainNavScreen> createState() => _TherapistMainNavScreenState();
}

class _TherapistMainNavScreenState extends State<TherapistMainNavScreen> {
  int _currentIndex = 0;

  final GlobalKey<TherapistAvailabilityScreenState> _availabilityKey =
      GlobalKey<TherapistAvailabilityScreenState>();

  late final List<Widget> _pages = [
    const TherapistHomeScreen(),
    TherapistAvailabilityScreen(key: _availabilityKey),
    TherapistProfileScreen(onNavigateToTab: _onTap),
  ];

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      _availabilityKey.currentState?.refreshSchedule();
    }
  }

  Widget _navIcon(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brown : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: isSelected
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Icon(icon, color: AppColors.brown, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 68,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navIcon(Icons.home_rounded, 'Home', 0),
              _navIcon(Icons.calendar_month_rounded, 'Availability', 1),
              _navIcon(Icons.person_rounded, 'Profile', 2),
            ],
          ),
        ),
      ),
    );
  }
}