import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/therapist_schedule_model.dart';
import '../../services/therapist_api_service.dart';
import '../notifications_screen.dart';

const List<String> _kAllTimeSlots = [
  '11:00 AM - 12:00 PM',
  '12:00 PM - 1:00 PM',
  '1:00 PM - 2:00 PM',
  '2:00 PM - 3:00 PM',
  '3:00 PM - 4:00 PM',
  '4:00 PM - 5:00 PM',
  '5:00 PM - 6:00 PM',
  '6:00 PM - 7:00 PM',
  '7:00 PM - 8:00 PM',
  '8:00 PM - 9:00 PM',
  '9:00 PM - 10:00 PM',
  '10:00 PM - 11:00 PM',
];

const Color _kAvailableColor = Color(0xFF5FA83D);
const Color _kReservedColor = Color(0xFF9E9E9E);

class TherapistAvailabilityScreen extends StatefulWidget {
  const TherapistAvailabilityScreen({super.key});

  @override
  State<TherapistAvailabilityScreen> createState() =>
      TherapistAvailabilityScreenState();
}

class TherapistAvailabilityScreenState
    extends State<TherapistAvailabilityScreen> {
  DateTime _selectedDate = DateTime.now();
  TherapistScheduleModel? _mySchedule;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final schedule = await TherapistApiService.fetchMySchedule(
        date: _formattedDate(_selectedDate),
      );
      setState(() {
        _mySchedule = schedule;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load your availability.';
        _isLoading = false;
      });
    }
  }

  Future<void> refreshSchedule() async {
    await _loadSchedule();
  }

  String _formattedDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(primary: AppColors.darkBrown),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadSchedule();
    }
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          fetchNotifications: TherapistApiService.fetchNotifications,
          markAsRead: TherapistApiService.markNotificationRead,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My Availability',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _openNotifications,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.darkBrown,
                    child: const Icon(Icons.notifications, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.darkBrown,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brown.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _displayDate(_selectedDate),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(_kAvailableColor, 'Available'),
                const SizedBox(width: 28),
                _legendDot(_kReservedColor, 'Reserved'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.brown),
                    )
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: GoogleFonts.poppins(color: AppColors.brown),
                          ),
                        )
                      : _mySchedule == null
                          ? Center(
                              child: Text(
                                'No schedule found.',
                                style: GoogleFonts.poppins(color: AppColors.brown),
                              ),
                            )
                          : RefreshIndicator(
                              color: AppColors.brown,
                              onRefresh: _loadSchedule,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 24),
                                child: _TherapistScheduleCard(schedule: _mySchedule!),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TherapistScheduleCard extends StatelessWidget {
  final TherapistScheduleModel schedule;

  const _TherapistScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            schedule.fullName,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _kAllTimeSlots.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.7,
            ),
            itemBuilder: (context, index) {
              final slot = _kAllTimeSlots[index];
              final isAvailable = schedule.availableSlots.contains(slot);
              return _SlotPill(label: slot, isAvailable: isAvailable);
            },
          ),
        ],
      ),
    );
  }
}

class _SlotPill extends StatelessWidget {
  final String label;
  final bool isAvailable;

  const _SlotPill({required this.label, required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? _kAvailableColor : _kReservedColor;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color, width: 2.4),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}