import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/home_api_service.dart';
import 'book_appointment_flow.dart';
import 'notifications_screen.dart';

class PaladCareScreen extends StatefulWidget {
  const PaladCareScreen({super.key});

  @override
  State<PaladCareScreen> createState() => _PaladCareScreenState();
}

class _ChatEntry {
  final String sender; // 'user' | 'bot'
  final String text;

  _ChatEntry({required this.sender, required this.text});
}

class _PaladCareScreenState extends State<PaladCareScreen> {
  final List<_ChatEntry> _chat = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _historyLoaded = false;
  bool _isSending = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _chat.add(_ChatEntry(
      sender: 'bot',
      text: '"Kumusta! Ako si PaladCare — handang gabayan ka para sa isang tunay na Mapalad na Araw!"',
    ));
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

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _ensureHistoryLoaded() async {
    if (_historyLoaded) return;
    _historyLoaded = true;
    try {
      final messages = await HomeApiService.fetchChatMessages();
      if (messages.isNotEmpty && mounted) {
        setState(() {
          _chat.insertAll(1, messages.map((m) => _ChatEntry(sender: m.sender, text: m.message)));
        });
      }
    } catch (_) {
      // best-effort — if history fails to load, just continue without it
    }
  }

  Future<void> _appendUserMessage(String text) async {
    await _ensureHistoryLoaded();
    if (!mounted) return;
    setState(() {
      _chat.add(_ChatEntry(sender: 'user', text: text));
    });
    _scrollToBottom();
    HomeApiService.sendChatMessage(sender: 'user', message: text)
        .catchError((e) => debugPrint('PaladCare save failed: $e'));
  }

  Future<void> _addBotReply(String text) async {
    if (!mounted) return;
    setState(() {
      _chat.add(_ChatEntry(sender: 'bot', text: text));
    });
    _scrollToBottom();
    HomeApiService.sendChatMessage(sender: 'bot', message: text)
        .catchError((e) => debugPrint('PaladCare save failed: $e'));
  }

  Future<void> _handleUserAction(String label, Future<void> Function() handler) async {
    if (_isSending) return;
    setState(() => _isSending = true);
    try {
      await _appendUserMessage(label);
      await handler();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleFreeText(String rawText) async {
    if (_isSending) return;
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return;
    _textController.clear();
    setState(() => _isSending = true);
    try {
      await _appendUserMessage(trimmed);
      final lower = trimmed.toLowerCase();
      if (lower.contains('service')) {
        await _showOurServices();
      } else if (lower.contains('branch') || lower.contains('location')) {
        await _showBranchLocations();
      } else if (lower.contains('book') || lower.contains('appointment') || lower.contains('reserve')) {
        await _bookAppointment();
      } else if (lower.contains('therapist') || lower.contains('availab')) {
        await _therapistAvailability();
      } else if (lower.contains('booking status') || lower.contains('my booking') || lower.contains('status')) {
        await _checkBookingStatus();
      } else if (lower.contains('hour') || lower.contains('open')) {
        await _operatingHours();
      } else {
        await _addBotReply("I'm not sure I understand that. Please choose one of the options below so I can help you better!");
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _showOurServices() async {
    try {
      final categories = await HomeApiService.fetchCategories();
      final services = await HomeApiService.fetchServices();

      final buffer = StringBuffer('Here are all our services:\n');
      for (final category in categories) {
        final servicesInCategory = services.where((s) => s.categoryId == category.categoryId).toList();
        if (servicesInCategory.isEmpty) continue;
        buffer.writeln();
        buffer.writeln(category.categoryName);
        for (final service in servicesInCategory) {
          buffer.writeln('• ${service.serviceName} — PHP ${service.price.toStringAsFixed(2)} (${service.duration})');
        }
      }
      await _addBotReply(buffer.toString().trim());
    } catch (e) {
      await _addBotReply('Sorry, I could not load our services right now. Please try again later.');
    }
  }

  Future<void> _showBranchLocations() async {
    try {
      final branches = await HomeApiService.fetchBranches();
      final buffer = StringBuffer('Here are all our branches:\n');
      for (var i = 0; i < branches.length; i++) {
        final branch = branches[i];
        buffer.writeln();
        buffer.writeln('${i + 1}. ${branch.branchName}');
        buffer.writeln('   ${branch.branchAddress}');
      }
      await _addBotReply(buffer.toString().trim());
    } catch (e) {
      await _addBotReply('Sorry, I could not load our branches right now. Please try again later.');
    }
  }

  Future<void> _bookAppointment() async {
    await _addBotReply("Great choice! Let's get your appointment booked.");
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => BookAppointmentFlow()));
  }

  Future<void> _therapistAvailability() async {
    await _addBotReply('Please select a date to check therapist availability:');
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (!mounted) return;
    if (pickedDate == null) {
      await _addBotReply('No date selected. Feel free to check again anytime!');
      return;
    }
    final dateStr =
        '${pickedDate.year.toString().padLeft(4, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';

    try {
      final schedule = await HomeApiService.fetchTherapistSchedule(dateStr);
      if (schedule.isEmpty) {
        await _addBotReply('No therapists found.');
        return;
      }
      final buffer = StringBuffer('Therapist schedule for $dateStr:\n');
      for (final therapist in schedule) {
        buffer.writeln();
        buffer.writeln(therapist.fullName);
        buffer.writeln(
          therapist.availableSlots.isEmpty
              ? 'Fully booked for this date.'
              : 'Available: ${therapist.availableSlots.join(', ')}',
        );
      }
      await _addBotReply(buffer.toString().trim());
    } catch (e) {
      await _addBotReply('Sorry, I could not load the therapist schedule right now. Please try again later.');
    }
  }

  Future<void> _checkBookingStatus() async {
    try {
      final bookings = await HomeApiService.fetchMyBookings();
      final reserved = bookings.where((b) => b.status == 'pending').toList();
      if (reserved.isEmpty) {
        await _addBotReply('You have no reserved bookings at the moment.');
        return;
      }
      final buffer = StringBuffer('Here are your current reserved bookings:\n');
      for (final booking in reserved) {
        buffer.writeln();
        buffer.writeln(booking.serviceName);
        buffer.writeln('Branch: ${booking.branchName}');
        buffer.writeln('Date: ${booking.appointmentDate}');
        buffer.writeln('Time: ${booking.timeSlot}');
        buffer.writeln('Therapist: ${booking.therapistName ?? 'Any Therapist'}');
        buffer.writeln('Status: RESERVED');
      }
      await _addBotReply(buffer.toString().trim());
    } catch (e) {
      await _addBotReply('Sorry, I could not load your booking status right now. Please try again later.');
    }
  }

  Future<void> _operatingHours() async {
    try {
      final branches = await HomeApiService.fetchBranches();
      final buffer = StringBuffer('Operating hours for all branches:\n');
      for (final branch in branches) {
        buffer.writeln();
        buffer.writeln(branch.branchName);
        buffer.writeln('Open: 11:00 AM - 11:00 PM');
      }
      await _addBotReply(buffer.toString().trim());
    } catch (e) {
      await _addBotReply('Sorry, I could not load branch hours right now. Please try again later.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Stack(
              children: [
                _buildChatList(),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: _buildQuickReplies(),
                ),
              ],
            ),
          ),
          _buildInputBar(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'PaladCare',
              style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 28),
            ),
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
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 84),
      itemCount: _chat.length,
      itemBuilder: (context, index) {
        final entry = _chat[index];
        final isBot = entry.sender == 'bot';
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              if (isBot && index == 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Center(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.brown, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset('assets/images/paladcare.png', fit: BoxFit.cover),
                    ),
                  ),
                ),
              Align(
                alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isBot ? AppColors.darkBrown : AppColors.offWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isBot ? 4 : 18),
                      bottomRight: Radius.circular(isBot ? 18 : 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brown.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    entry.text,
                    style: GoogleFonts.poppins(
                      color: isBot ? Colors.white : AppColors.darkBrown,
                      fontWeight: FontWeight.w700,
                      fontStyle: isBot ? FontStyle.italic : FontStyle.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickReplies() {
    final buttons = <Widget>[
      _quickReplyButton('Our Services', () => _handleUserAction('Our Services', _showOurServices)),
      _quickReplyButton('Branch Locations', () => _handleUserAction('Branch Locations', _showBranchLocations)),
      _quickReplyButton('Book an Appointment', () => _handleUserAction('Book an Appointment', _bookAppointment)),
      _quickReplyButton('Therapist Availability', () => _handleUserAction('Therapist Availability', _therapistAvailability)),
      _quickReplyButton('Check my Booking Status', () => _handleUserAction('Check my Booking Status', _checkBookingStatus)),
      _quickReplyButton('Operating Hours', () => _handleUserAction('Operating Hours', _operatingHours)),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        itemCount: buttons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => buttons[index],
      ),
    );
  }

  Widget _quickReplyButton(String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: _isSending ? null : onTap,
    child: Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFAF8F6F),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.brown, width: 1.6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
  );
}

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brown.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                onSubmitted: _handleFreeText,
                style: GoogleFonts.poppins(color: AppColors.darkBrown, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Enter a message or click on one of the options.',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12.5),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSending ? null : () => _handleFreeText(_textController.text),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.darkBrown),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}