import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book a Service',
            style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const Expanded(
            child: Center(
              child: Text('Booking flow goes here'),
            ),
          ),
        ],
      ),
    );
  }
}