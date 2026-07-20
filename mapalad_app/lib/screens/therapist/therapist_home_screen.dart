import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../services/home_api_service.dart';
import '../../services/therapist_api_service.dart';
import '../../widgets/booking_receipt_card.dart';
import '../notifications_screen.dart';

class TherapistHomeScreen extends StatefulWidget {
  const TherapistHomeScreen({super.key});

  @override
  State<TherapistHomeScreen> createState() => _TherapistHomeScreenState();
}

class _StatusStyle {
  final Color background;
  final Color text;
  final String label;
  const _StatusStyle(this.background, this.text, this.label);
}

class _TherapistHomeScreenState extends State<TherapistHomeScreen> {
  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  bool _isLoading = true;
  String? _loadError;
  List<BookingModel> _bookings = [];
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  int _unreadCount = 0;
  String? _profilePicture;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadProfilePicture();
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final bookings = await TherapistApiService.fetchBookings(date: _dateKey(_selectedDate));
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
      _refreshUnreadCount();
    } catch (e) {
      setState(() {
        _loadError = 'Could not load your bookings. Is the backend running?';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfilePicture() async {
    try {
      final profile = await HomeApiService.fetchProfile();
      if (!mounted) return;
      setState(() {
        _profilePicture = profile['profilePicture'] as String?;
      });
    } catch (_) {
      // Avatar just won't show a picture this cycle.
    }
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final notifications = await TherapistApiService.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _unreadCount = notifications.where((n) => !n.isRead).length;
      });
    } catch (_) {
      // Badge just won't update this cycle.
    }
  }

  void _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          fetchNotifications: TherapistApiService.fetchNotifications,
          markAsRead: TherapistApiService.markNotificationRead,
        ),
      ),
    );
    _refreshUnreadCount();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.darkBrown),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  String _formatDisplayDate(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  _StatusStyle _statusStyle(String status) {
    switch (status) {
      case 'completed':
        return const _StatusStyle(Color(0xFFE3E3E3), Color(0xFF6E6E6E), 'COMPLETED');
      case 'cancelled':
        return const _StatusStyle(Color(0xFFFADCDC), Color(0xFFE15252), 'CANCELLED');
      case 'confirmed':
        return const _StatusStyle(Color(0xFFDCEAFB), Color(0xFF2E6FCB), 'CONFIRMED');
      case 'pending':
      default:
        return const _StatusStyle(Color(0xFFFCE7C6), Color(0xFFCB8E2E), 'RESERVED');
    }
  }

  List<BookingModel> get _visibleBookings {
    if (_searchQuery.trim().isEmpty) return _bookings;
    final query = _searchQuery.trim().toLowerCase();
    return _bookings.where((b) {
      return b.fullName.toLowerCase().contains(query) ||
          b.serviceName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppColors.darkBrown)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.darkBrown,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateBar(),
                  const SizedBox(height: 16),
                  if (_visibleBookings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No bookings for this date.', style: GoogleFonts.poppins(color: AppColors.brown)),
                      ),
                    )
                  else
                    for (final booking in _visibleBookings) ...[
                      _buildBookingCard(booking),
                      const SizedBox(height: 14),
                    ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.darkBrown,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown.withOpacity(0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.offWhite,
                backgroundImage: _profilePicture != null
                    ? MemoryImage(base64Decode(_profilePicture!))
                    : null,
                child: _profilePicture == null
                    ? Icon(Icons.person, color: AppColors.darkBrown, size: 26)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mapalad Na Araw!', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                    Text('Therapist', style: GoogleFonts.poppins(color: AppColors.lightBrown, fontStyle: FontStyle.italic, fontSize: 12)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _openNotifications,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.offWhite),
                      child: Icon(Icons.notifications_rounded, color: AppColors.darkBrown, size: 20),
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE15252),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Find a Transaction', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 19)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(30)),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBar() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.darkBrown, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(_formatDisplayDate(_selectedDate), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final style = _statusStyle(booking.status);
    final canComplete = booking.status == 'confirmed';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBrown, width: 2.2),
        boxShadow: [BoxShadow(color: AppColors.brown.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.serviceName, style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 16)),
                    if (booking.categoryName != null && booking.categoryName!.isNotEmpty)
                      Text(booking.categoryName!, style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.w600, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: style.background, borderRadius: BorderRadius.circular(20)),
                child: Text(style.label, style: GoogleFonts.poppins(color: style.text, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showReceiptDialog(booking),
                child: Icon(Icons.remove_red_eye_outlined, color: Colors.grey[500], size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(booking.fullName, style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 14)),
          Text('Duration: ${booking.duration}', style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.w600, fontSize: 11)),
          const SizedBox(height: 4),
          Text('PHP ${booking.price.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.w800, fontSize: 13)),
          if (canComplete) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: TextButton(
                onPressed: () => _confirmAction(
                  booking: booking,
                  title: 'Mark this booking as completed?',
                  confirmLabel: 'Yes, Mark as Completed',
                  confirmColor: const Color(0xFF3FA34D),
                  onConfirm: () => _updateStatus(booking, 'completed'),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.darkBrown,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Mark as Complete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmAction({
    required BookingModel booking,
    required String title,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
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
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onConfirm();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: confirmColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    confirmLabel,
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'No',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BookingModel booking, String newStatus) async {
    try {
      await TherapistApiService.updateBookingStatus(booking.bookingId, newStatus);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this booking. Please try again.')),
      );
    }
  }

  void _showReceiptDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            BookingReceiptCard(booking: booking),
            Positioned(
              top: -12,
              right: -12,
              child: GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.darkBrown,
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}