import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../models/receptionist_dashboard_model.dart';
import '../../models/therapist_model.dart';
import '../../models/sales_per_service_model.dart';
import '../../models/branch_bookings_model.dart';
import '../../models/branch_model.dart';
import '../../services/home_api_service.dart';
import '../../services/receptionist_api_service.dart';
import '../../widgets/booking_receipt_card.dart';
import '../notifications_screen.dart';

class ReceptionistHomeScreen extends StatefulWidget {
  const ReceptionistHomeScreen({super.key});

  @override
  State<ReceptionistHomeScreen> createState() => _ReceptionistHomeScreenState();
}

class _StatusStyle {
  final Color background;
  final Color text;
  final String label;
  const _StatusStyle(this.background, this.text, this.label);
}

class _ReceptionistHomeScreenState extends State<ReceptionistHomeScreen> {
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
  ReceptionistDashboardModel? _dashboard;
  List<TherapistModel> _therapists = [];
  List<BranchModel> _allBranches = [];
  Set<String> _selectedBranchIds = {};
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String _statusFilter = 'all';
  int _unreadCount = 0;
  String? _profilePicture;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadProfilePicture();
    _loadBranches();
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        ReceptionistApiService.fetchDashboard(date: _dateKey(_selectedDate)),
        ReceptionistApiService.fetchTherapists(),
      ]);
      setState(() {
        _dashboard = results[0] as ReceptionistDashboardModel;
        _therapists = results[1] as List<TherapistModel>;
        _isLoading = false;
      });
      _refreshUnreadCount();
    } catch (e) {
      setState(() {
        _loadError = 'Could not load dashboard. Is the backend running?';
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

  Future<void> _loadBranches() async {
    try {
      final branches = await ReceptionistApiService.fetchBranches();
      if (!mounted) return;
      setState(() {
        _allBranches = branches;
        _selectedBranchIds = branches.map((b) => b.branchId).toSet();
      });
    } catch (_) {
      // Branch filter just won't be available this cycle; charts show unfiltered data.
    }
  }

  bool get _branchFilterReady => _allBranches.isNotEmpty;

  Set<String> get _selectedBranchNames => _allBranches
      .where((b) => _selectedBranchIds.contains(b.branchId))
      .map((b) => b.branchName)
      .toSet();

  Future<void> _openBranchFilter() async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _BranchFilterDialog(
        branches: _allBranches,
        initiallySelected: _selectedBranchIds,
      ),
    );
    if (result != null) {
      setState(() => _selectedBranchIds = result);
    }
  }

  double _filteredServiceSales(SalesPerServiceModel service) {
    if (!_branchFilterReady) return service.totalSales;
    final names = _selectedBranchNames;
    if (names.isEmpty) return 0;
    double sum = 0;
    service.salesByBranch.forEach((branchName, amount) {
      if (names.contains(branchName)) sum += amount;
    });
    return sum;
  }

  List<BranchBookingsModel> _filteredBranchBookings(List<BranchBookingsModel> all) {
    if (!_branchFilterReady) return all;
    final names = _selectedBranchNames;
    return all.where((b) => names.contains(b.branchName)).toList();
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final notifications = await ReceptionistApiService.fetchNotifications();
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
          fetchNotifications: ReceptionistApiService.fetchNotifications,
          markAsRead: ReceptionistApiService.markNotificationRead,
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

  String _formatCurrency(double value) {
    final isNegative = value < 0;
    final fixed = value.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < fixed.length; i++) {
      if (i > 0 && (fixed.length - i) % 3 == 0) buffer.write(',');
      buffer.write(fixed[i]);
    }
    return '${isNegative ? '-' : ''}$buffer';
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
    final bookings = _dashboard?.bookings ?? [];
    Iterable<BookingModel> filtered = bookings;

    if (_statusFilter != 'all') {
      filtered = filtered.where((b) => b.status == _statusFilter);
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((b) =>
          b.fullName.toLowerCase().contains(query) ||
          b.serviceName.toLowerCase().contains(query));
    }

    return filtered.toList();
  }

  String _firstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  double _niceInterval(double maxValue) {
    if (maxValue <= 0) return 1;
    return maxValue / 4;
  }

  double _barAxisInterval(int maxValue) {
    if (maxValue <= 5) return 1;
    return (maxValue / 5).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null || _dashboard == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError ?? 'Something went wrong.', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppColors.darkBrown)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final dashboard = _dashboard!;
    final isGrowthPositive = dashboard.salesGrowthPercent >= 0;

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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTopServicesCard(dashboard)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          children: [
                            _buildTotalSalesCard(dashboard, isGrowthPositive),
                            const SizedBox(height: 14),
                            _buildBookingsTodayCard(dashboard),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildBranchFilterPill(),
                  const SizedBox(height: 20),
                  _buildSalesPerServiceChart(dashboard),
                  const SizedBox(height: 14),
                  _buildBookingsPerBranchChart(dashboard),
                  const SizedBox(height: 20),
                  _buildDateBar(),
                  const SizedBox(height: 12),
                  _buildStatusFilterBar(),
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
                    Text('Receptionist', style: GoogleFonts.poppins(color: AppColors.lightBrown, fontStyle: FontStyle.italic, fontSize: 12)),
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

  Widget _buildTopServicesCard(ReceptionistDashboardModel dashboard) {
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
          Text('Top Services', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          if (dashboard.topServices.isEmpty)
            Text('No bookings yet.', style: GoogleFonts.poppins(color: AppColors.brown, fontSize: 12))
          else
            for (int i = 0; i < dashboard.topServices.length; i++) ...[
              _buildTopServiceItem(i + 1, dashboard.topServices[i]),
              if (i != dashboard.topServices.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _buildTopServiceItem(int rank, dynamic service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(color: AppColors.lightBrown, borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.centerRight,
          child: Text('${service.bookingCount} Bookings', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10)),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$rank', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w900, fontSize: 26)),
            const SizedBox(width: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(service.serviceName, style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalSalesCard(ReceptionistDashboardModel dashboard, bool isGrowthPositive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBrown,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.brown.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Sales', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          Text('₱ ${_formatCurrency(dashboard.totalSales)}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(isGrowthPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isGrowthPositive ? const Color(0xFF7CE38B) : const Color(0xFFE38B8B), size: 16),
              const SizedBox(width: 2),
              Text('${dashboard.salesGrowthPercent.abs().toStringAsFixed(1)} %',
                  style: GoogleFonts.poppins(
                      color: isGrowthPositive ? const Color(0xFF7CE38B) : const Color(0xFFE38B8B),
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text('across all branches', style: GoogleFonts.poppins(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildBookingsTodayCard(ReceptionistDashboardModel dashboard) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBrown, width: 2.2),
        boxShadow: [BoxShadow(color: AppColors.brown.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bookings\nToday', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          Text('${dashboard.bookingsToday}', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w900, fontSize: 32)),
        ],
      ),
    );
  }

  Widget _buildBranchFilterPill() {
    return GestureDetector(
      onTap: _allBranches.isEmpty ? null : _openBranchFilter,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Select Branches',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesPerServiceChart(ReceptionistDashboardModel dashboard) {
    final data = dashboard.salesPerService;
    final values = [for (final s in data) _filteredServiceSales(s)];
    final maxSales = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxSales <= 0 ? 100.0 : maxSales * 1.2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBrown, width: 2.2),
        boxShadow: [BoxShadow(color: AppColors.brown.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sales per Service', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 2),
          Text('Top 5 services by revenue', style: GoogleFonts.poppins(color: AppColors.brown, fontSize: 11, fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('No completed sales yet.', style: GoogleFonts.poppins(color: AppColors.brown, fontSize: 12))),
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: chartMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _niceInterval(chartMaxY),
                    getDrawingHorizontalLine: (value) => FlLine(color: AppColors.lightBrown.withOpacity(0.25), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) => Text(
                          '₱${value.toInt()}',
                          style: GoogleFonts.poppins(color: AppColors.brown, fontSize: 9),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) return const SizedBox.shrink();
                          final name = data[index].serviceName;
                          final label = name.length > 10 ? '${name.substring(0, 10)}…' : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                label,
                                style: GoogleFonts.poppins(color: AppColors.darkBrown, fontSize: 9, fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), values[i]),
                      ],
                      isCurved: true,
                      color: AppColors.darkBrown,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.brown,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.lightBrown.withOpacity(0.18),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => AppColors.darkBrown,
                      getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        final name = index >= 0 && index < data.length ? data[index].serviceName : '';
                        return LineTooltipItem(
                          '$name\n₱${spot.y.toStringAsFixed(0)}',
                          GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingsPerBranchChart(ReceptionistDashboardModel dashboard) {
    final data = _filteredBranchBookings(dashboard.bookingsPerBranch);
    final maxCount = data.isEmpty ? 0 : data.map((e) => e.completedCount).reduce((a, b) => a > b ? a : b);
    final chartMaxY = (maxCount + (maxCount == 0 ? 1 : (maxCount * 0.2).ceil())).toDouble();
    final axisInterval = _barAxisInterval(maxCount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBrown, width: 2.2),
        boxShadow: [BoxShadow(color: AppColors.brown.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bookings per Branch', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 2),
          Text('Completed bookings, all branches', style: GoogleFonts.poppins(color: AppColors.brown, fontSize: 11, fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('No completed bookings yet.', style: GoogleFonts.poppins(color: AppColors.brown, fontSize: 12))),
            )
          else
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: chartMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: axisInterval,
                    getDrawingHorizontalLine: (value) => FlLine(color: AppColors.lightBrown.withOpacity(0.25), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: axisInterval,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}',
                          style: GoogleFonts.poppins(color: AppColors.brown, fontSize: 9),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) return const SizedBox.shrink();
                          final name = data[index].branchName;
                          final label = name.length > 9 ? '${name.substring(0, 9)}…' : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                label,
                                style: GoogleFonts.poppins(color: AppColors.darkBrown, fontSize: 9, fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < data.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i].completedCount.toDouble(),
                            color: AppColors.brown,
                            width: 18,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: chartMaxY,
                              color: AppColors.offWhite,
                            ),
                          ),
                        ],
                      ),
                  ],
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => AppColors.darkBrown,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final name = groupIndex >= 0 && groupIndex < data.length ? data[groupIndex].branchName : '';
                        return BarTooltipItem(
                          '$name\n${rod.toY.toInt()} bookings',
                          GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ),
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
    final canCancel = booking.status == 'pending' || booking.status == 'confirmed';
    final canConfirm = booking.status == 'pending';
    final hasTherapist = booking.therapistId != null && booking.therapistId!.isNotEmpty;

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
          const SizedBox(height: 10),
          _buildTherapistField(booking),
          const SizedBox(height: 12),
          if (canCancel)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextButton(
                      onPressed: () => _confirmAction(
                        booking: booking,
                        title: 'Cancel this booking?',
                        confirmLabel: 'Yes, Cancel this booking',
                        confirmColor: const Color(0xFFE15252),
                        onConfirm: () => _updateStatus(booking, 'cancelled'),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFE15252),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ),
                if (canConfirm) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: Tooltip(
                        message: hasTherapist ? '' : 'Assign a therapist before confirming',
                        child: TextButton(
                          onPressed: hasTherapist
                              ? () => _confirmAction(
                                    booking: booking,
                                    title: 'Confirm this booking?',
                                    confirmLabel: 'Yes, Confirm this booking',
                                    confirmColor: const Color(0xFF2E6FCB),
                                    onConfirm: () => _updateStatus(booking, 'confirmed'),
                                  )
                              : null,
                          style: TextButton.styleFrom(
                            backgroundColor: hasTherapist ? AppColors.darkBrown : Colors.grey[400],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text('Confirm', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTherapistField(BookingModel booking) {
    final hasSpecificTherapist = booking.therapistId != null && booking.therapistId!.isNotEmpty;

    if (hasSpecificTherapist) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(10)),
        child: Text(
          _firstName(booking.therapistName ?? ''),
          style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text('Any Therapist', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w600, fontSize: 13)),
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.darkBrown),
          items: _therapists
              .map((t) => DropdownMenuItem(
                    value: t.uid,
                    child: Text(t.fullName, style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w600, fontSize: 13)),
                  ))
              .toList(),
          onChanged: (selectedUid) {
            if (selectedUid == null) return;
            final selected = _therapists.firstWhere((t) => t.uid == selectedUid);
            _assignTherapist(booking, selected.uid, selected.fullName);
          },
        ),
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
      await ReceptionistApiService.updateBookingStatus(booking.bookingId, newStatus);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this booking. Please try again.')),
      );
    }
  }

  Future<void> _assignTherapist(BookingModel booking, String therapistId, String therapistName) async {
    try {
      await ReceptionistApiService.assignTherapist(booking.bookingId, therapistId, therapistName);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not assign therapist. Please try again.')),
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

class _BranchFilterDialog extends StatefulWidget {
  final List<BranchModel> branches;
  final Set<String> initiallySelected;

  const _BranchFilterDialog({
    required this.branches,
    required this.initiallySelected,
  });

  @override
  State<_BranchFilterDialog> createState() => _BranchFilterDialogState();
}

class _BranchFilterDialogState extends State<_BranchFilterDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initiallySelected};
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Branches',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: Column(
                  children: widget.branches.map((b) {
                    final checked = _selected.contains(b.branchId);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selected.add(b.branchId);
                          } else {
                            _selected.remove(b.branchId);
                          }
                        });
                      },
                      title: Text(
                        b.branchName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      activeColor: AppColors.brown,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}