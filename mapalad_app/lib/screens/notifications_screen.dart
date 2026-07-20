import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  final Future<List<NotificationModel>> Function() fetchNotifications;
  final Future<void> Function(String notificationId) markAsRead;

  const NotificationsScreen({
    super.key,
    required this.fetchNotifications,
    required this.markAsRead,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String? _loadError;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final notifications = await widget.fetchNotifications();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Could not load notifications. Is the backend running?';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleTap(NotificationModel notification) async {
    if (notification.isRead) return;
    setState(() {
      final index = _notifications.indexWhere((n) => n.notificationId == notification.notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          notificationId: notification.notificationId,
          recipientId: notification.recipientId,
          recipientRole: notification.recipientRole,
          bookingId: notification.bookingId,
          type: notification.type,
          title: notification.title,
          message: notification.message,
          isRead: true,
          createdAt: notification.createdAt,
        );
      }
    });
    try {
      await widget.markAsRead(notification.notificationId);
    } catch (_) {
      // Silent — read state resyncs on next refresh either way.
    }
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return '${diff.inSeconds} sec';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  ({IconData icon, Color color}) _iconFor(String type) {
    switch (type) {
      case 'booking_cancelled_by_customer':
      case 'booking_cancelled_by_receptionist':
        return (icon: Icons.priority_high_rounded, color: const Color(0xFFE15252));
      case 'booking_confirmed':
        return (icon: Icons.event_available_rounded, color: AppColors.darkBrown);
      case 'booking_completed':
        return (icon: Icons.check_rounded, color: AppColors.darkBrown);
      case 'reminder_1day':
      case 'reminder_8hr':
        return (icon: Icons.access_time_rounded, color: AppColors.darkBrown);
      default:
        return (icon: Icons.notifications_rounded, color: AppColors.darkBrown);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.darkBrown,
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Text('Notification', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildBody() {
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
    if (_notifications.isEmpty) {
      return RefreshIndicator(
        color: AppColors.darkBrown,
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: Text('No notifications yet.', style: GoogleFonts.poppins(color: AppColors.brown)),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final today = <NotificationModel>[];
    final earlier = <NotificationModel>[];
    for (final n in _notifications) {
      final isToday = n.createdAt.year == now.year && n.createdAt.month == now.month && n.createdAt.day == now.day;
      (isToday ? today : earlier).add(n);
    }

    return RefreshIndicator(
      color: AppColors.darkBrown,
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          if (today.isNotEmpty) ...[
            Text('Today', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 12),
            for (final n in today) ...[_buildNotificationTile(n), const SizedBox(height: 14)],
          ],
          if (earlier.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Earlier', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 12),
            for (final n in earlier) ...[_buildNotificationTile(n), const SizedBox(height: 14)],
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    final style = _iconFor(notification.type);

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: style.color,
          child: Icon(style.icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                  Text(
                    _relativeTime(notification.createdAt),
                    style: GoogleFonts.poppins(color: AppColors.brown, fontStyle: FontStyle.italic, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                notification.message,
                style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.w500, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () => _handleTap(notification),
      child: notification.isRead
          ? Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: row)
          : Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.darkBrown, width: 2.2),
                boxShadow: [BoxShadow(color: AppColors.brown.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: row,
            ),
    );
  }
}