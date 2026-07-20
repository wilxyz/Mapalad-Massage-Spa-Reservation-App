import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/booking_model.dart';
import '../services/home_api_service.dart';
import '../widgets/booking_receipt_card.dart';
import 'notifications_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _StatusStyle {
  final Color background;
  final Color text;
  final String label;
  const _StatusStyle(this.background, this.text, this.label);
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'All'},
    {'value': 'pending', 'label': 'Reserved'},
    {'value': 'confirmed', 'label': 'Confirmed'},
    {'value': 'completed', 'label': 'Completed'},
    {'value': 'cancelled', 'label': 'Cancelled'},
  ];

  bool _isLoading = true;
  String? _loadError;
  List<BookingModel> _bookings = [];
  String _statusFilter = 'all';
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final notifications = await HomeApiService.fetchNotifications();
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
          fetchNotifications: HomeApiService.fetchNotifications,
          markAsRead: HomeApiService.markNotificationRead,
        ),
      ),
    );
    _refreshUnreadCount();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final bookings = await HomeApiService.fetchMyBookings();
      bookings.sort((a, b) => b.appointmentDateTime.compareTo(a.appointmentDateTime));
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Could not load booking history. Is the backend running?';
        _isLoading = false;
      });
    }
  }

  List<BookingModel> get _visibleBookings {
    if (_statusFilter == 'all') return _bookings;
    return _bookings.where((b) => b.status == _statusFilter).toList();
  }

  Map<String, List<BookingModel>> _groupByMonth(List<BookingModel> bookings) {
    final grouped = <String, List<BookingModel>>{};
    for (final booking in bookings) {
      final date = booking.appointmentDateTime;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(booking);
    }
    return grouped;
  }

  String _monthLabel(String key) {
    final month = int.parse(key.split('-')[1]);
    return _monthNames[month - 1];
  }

  _StatusStyle _statusStyle(String status) {
    switch (status) {
      case 'completed':
        return const _StatusStyle(Color(0xFFD9F2DD), Color(0xFF3FA34D), 'COMPLETED');
      case 'cancelled':
        return const _StatusStyle(Color(0xFFFADCDC), Color(0xFFE15252), 'CANCELLED');
      case 'confirmed':
        return const _StatusStyle(Color(0xFFDCEAFB), Color(0xFF2E6FCB), 'CONFIRMED');
      case 'pending':
      default:
        return const _StatusStyle(Color(0xFFFCE7C6), Color(0xFFCB8E2E), 'RESERVED');
    }
  }

  void _showReceipt(BookingModel booking) {
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
              top: -14,
              right: -14,
              child: GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.darkBrown,
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BookingModel booking) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Cancel this booking?',
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
                    _cancelBooking(booking);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFE15252),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Yes, Cancel this booking',
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

  void _confirmDelete(BookingModel booking) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete this booking?',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          'This will permanently remove it from your history.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.w900, fontSize: 13, fontStyle: FontStyle.italic),
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
                    _deleteBooking(booking);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF6E6E6E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Yes, Delete this booking',
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

  Future<void> _cancelBooking(BookingModel booking) async {
    try {
      await HomeApiService.cancelBooking(booking.bookingId);
      setState(() {
        final index = _bookings.indexWhere((b) => b.bookingId == booking.bookingId);
        if (index != -1) {
          _bookings[index] = BookingModel(
            bookingId: booking.bookingId,
            serviceId: booking.serviceId,
            serviceName: booking.serviceName,
            categoryName: booking.categoryName,
            duration: booking.duration,
            price: booking.price,
            branchId: booking.branchId,
            branchName: booking.branchName,
            therapistId: booking.therapistId,
            therapistName: booking.therapistName,
            appointmentDate: booking.appointmentDate,
            timeSlot: booking.timeSlot,
            addOnId: booking.addOnId,
            addOnName: booking.addOnName,
            fullName: booking.fullName,
            contactNumber: booking.contactNumber,
            email: booking.email,
            specialRequests: booking.specialRequests,
            status: 'cancelled',
            createdAt: booking.createdAt,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel booking. Please try again.')),
      );
    }
  }

  Future<void> _deleteBooking(BookingModel booking) async {
    try {
      await HomeApiService.deleteBooking(booking.bookingId);
      setState(() {
        _bookings.removeWhere((b) => b.bookingId == booking.bookingId);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete booking. Please try again.')),
      );
    }
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
              ElevatedButton(onPressed: _loadBookings, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_bookings.isEmpty) {
      return RefreshIndicator(
        color: AppColors.darkBrown,
        onRefresh: _loadBookings,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: Text('No bookings yet.', style: GoogleFonts.poppins(color: AppColors.brown))),
            ),
          ),
        ),
      );
    }

    final visible = _visibleBookings;
    final grouped = _groupByMonth(visible);
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      color: Colors.white,
      child: RefreshIndicator(
        color: AppColors.darkBrown,
        onRefresh: _loadBookings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Booking History', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 28)),
                  ),
                  GestureDetector(
                    onTap: _openNotifications,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.darkBrown,
                          child: const Icon(Icons.notifications, color: Colors.white, size: 20),
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
              const SizedBox(height: 16),
              _buildStatusFilterBar(),
              const SizedBox(height: 20),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No bookings with this status.', style: GoogleFonts.poppins(color: AppColors.brown)),
                  ),
                )
              else
                for (final key in sortedKeys) ...[
                  Text(_monthLabel(key), style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 22)),
                  const SizedBox(height: 12),
                  for (final booking in grouped[key]!) ...[
                    _SwipeToCancelCard(
                      booking: booking,
                      onCancelTap: () => _confirmCancel(booking),
                      onDeleteTap: () => _confirmDelete(booking),
                      child: _buildBookingCard(booking),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterBar() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _statusFilters[index];
          final isSelected = _statusFilter == filter['value'];
          return GestureDetector(
            onTap: () => setState(() => _statusFilter = filter['value']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.darkBrown : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.darkBrown, width: 1.6),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.brown.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                filter['label']!,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : AppColors.darkBrown,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final style = _statusStyle(booking.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBrown, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.serviceName, style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                if (booking.categoryName != null && booking.categoryName!.isNotEmpty)
                  Text(booking.categoryName!, style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.w600, fontSize: 11)),
                if (booking.duration.isNotEmpty)
                  Text('Duration: ${booking.duration}', style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.w600, fontSize: 11)),
                const SizedBox(height: 4),
                Text('PHP ${booking.price.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: style.background, borderRadius: BorderRadius.circular(20)),
                child: Text(style.label, style: GoogleFonts.poppins(color: style.text, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showReceipt(booking),
                child: Icon(Icons.remove_red_eye_outlined, color: Colors.grey[500], size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _SwipeAction { cancel, delete, none }

class _SwipeToCancelCard extends StatefulWidget {
  final BookingModel booking;
  final Widget child;
  final VoidCallback onCancelTap;
  final VoidCallback onDeleteTap;

  const _SwipeToCancelCard({
    required this.booking,
    required this.child,
    required this.onCancelTap,
    required this.onDeleteTap,
  });

  @override
  State<_SwipeToCancelCard> createState() => _SwipeToCancelCardState();
}

class _SwipeToCancelCardState extends State<_SwipeToCancelCard> {
  static const double _revealWidth = 88;
  double _dragExtent = 0;
  bool _isDragging = false;

  _SwipeAction get _action {
    if (widget.booking.status == 'pending' || widget.booking.status == 'confirmed') {
      return _SwipeAction.cancel;
    }
    if (widget.booking.status == 'cancelled') {
      return _SwipeAction.delete;
    }
    return _SwipeAction.none;
  }

  @override
  Widget build(BuildContext context) {
    final action = _action;
    if (action == _SwipeAction.none) {
      return widget.child;
    }

    final isDelete = action == _SwipeAction.delete;
    final revealColor = isDelete ? const Color(0xFF6E6E6E) : const Color(0xFFE15252);
    final revealIcon = isDelete ? Icons.delete_outline_rounded : Icons.close_rounded;
    final revealLabel = isDelete ? 'Delete' : 'Cancel';
    final onTapAction = isDelete ? widget.onDeleteTap : widget.onCancelTap;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _isDragging = true;
          _dragExtent = (_dragExtent + details.delta.dx).clamp(-_revealWidth, 0.0);
        });
      },
      onHorizontalDragEnd: (details) {
        setState(() {
          _isDragging = false;
          _dragExtent = _dragExtent <= -_revealWidth / 2 ? -_revealWidth : 0.0;
        });
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: revealColor,
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _dragExtent = 0);
                    onTapAction();
                  },
                  child: SizedBox(
                    width: _revealWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(revealIcon, color: Colors.white, size: 22),
                        const SizedBox(height: 2),
                        Text(
                          revealLabel,
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: _isDragging ? Duration.zero : const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_dragExtent, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}