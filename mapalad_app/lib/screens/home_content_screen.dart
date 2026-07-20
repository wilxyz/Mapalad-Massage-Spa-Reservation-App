
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';
import '../models/branch_model.dart';
import '../services/home_api_service.dart';
import '../widgets/categories_dialog.dart';
import '../widgets/services_dialog.dart';
import '../widgets/branches_dialog.dart';
import 'book_appointment_flow.dart';
import 'notifications_screen.dart';

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<CategoryModel> _categories = [];
  List<ServiceModel> _allServices = [];
  List<ServiceModel> _displayedServices = [];
  List<BranchModel> _branches = [];

  String? _selectedCategoryId;
  String _fullName = 'Guest';
  String? _profilePicture;
  bool _isLoading = true;
  String? _loadError;
  int _unreadCount = 0;

  static const Map<String, String> _branchImages = {
    'Mapalad Massage and Spa-Lipa Bayan': 'assets/images/lipa_bayan.png',
    'Mapalad Massage and Spa-Tambo': 'assets/images/tambo.png',
    'Mapalad Massage and Spa-Ayala Highway': 'assets/images/ayala_highway.png',
    'Mapalad Massage and Spa-Marawouy': 'assets/images/marawouy.png',
    'Mapalad Massage and Spa-Rosario Batangas': 'assets/images/rosario.png',
    'Mapalad Massage and Spa-Santo Tomas': 'assets/images/santo_tomas.png',
    'Mapalad Massage and Spa-Kumintang Batangas City': 'assets/images/kumintang.png',
    'Mapalad Massage and Spa Tagaytay': 'assets/images/tagaytay.png',
  };

  String? _branchImagePath(String branchName) => _branchImages[branchName];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
  setState(() {
    _isLoading = true;
    _loadError = null;
  });
  try {
    final prefs = await SharedPreferences.getInstance();
    final results = await Future.wait([
      HomeApiService.fetchCategories(),
      HomeApiService.fetchServices(),
      HomeApiService.fetchBranches(),
    ]);

    final rawServices = results[1] as List<ServiceModel>;
    final rawBranches = results[2] as List<BranchModel>;

    final seenServiceKeys = <String>{};
    final dedupedServices = <ServiceModel>[];
    for (final s in rawServices) {
      final key = '${s.serviceName}|${s.categoryId}|${s.duration}|${s.price}';
      if (seenServiceKeys.add(key)) {
        dedupedServices.add(s);
      }
    }

    final seenBranchKeys = <String>{};
    final dedupedBranches = <BranchModel>[];
    for (final b in rawBranches) {
      final key = '${b.branchName}|${b.branchAddress}';
      if (seenBranchKeys.add(key)) {
        dedupedBranches.add(b);
      }
    }

    setState(() {
      _fullName = prefs.getString('fullName') ?? 'Guest';
      _categories = results[0] as List<CategoryModel>;
      _allServices = dedupedServices;
      _branches = dedupedBranches;
      _displayedServices = _allServices.take(3).toList();
      _isLoading = false;
    });

    _refreshUnreadCount();
    _checkReminders();
    _loadProfilePicture();
  } catch (e) {
    setState(() {
      _loadError = 'Could not load home data. Is the backend running?';
      _isLoading = false;
    });
  }
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

   Future<void> _loadProfilePicture() async {
    try {
      final profile = await HomeApiService.fetchProfile();
      if (!mounted) return;
      setState(() {
        _profilePicture = profile['profilePicture'] as String?;
      });
    } catch (_) {
      // Avatar just won't show this cycle.
    }
  }

  Future<void> _checkReminders() async {
    try {
      await HomeApiService.checkReminders();
    } catch (_) {
      // Non-critical — reminders will simply be checked again next load.
    }
  }

  void _selectCategory(String categoryId) {
    setState(() {
      if (_selectedCategoryId == categoryId) {
        _selectedCategoryId = null;
        _displayedServices = _allServices.take(3).toList();
      } else {
        _selectedCategoryId = categoryId;
        _displayedServices = _allServices.where((s) => s.categoryId == categoryId).toList();
      }
    });
  }

  String _categoryName(String categoryId) {
    final match = _categories.where((c) => c.categoryId == categoryId);
    return match.isNotEmpty ? match.first.categoryName : '';
  }

  void _onServiceSelected(ServiceModel service) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookAppointmentFlow(initialService: service)),
    );
  }

  void _onBranchSelected(BranchModel branch) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookAppointmentFlow(initialBranch: branch)),
    );
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

  void _showAllCategories() {
    showDialog(
      context: context,
      builder: (dialogContext) => CategoriesDialog(
        categories: _categories,
        selectedCategoryId: _selectedCategoryId,
        onSelect: (category) {
          Navigator.pop(dialogContext);
          _selectCategory(category.categoryId);
        },
      ),
    );
  }

  void _showAllServices() {
    showDialog(
      context: context,
      builder: (dialogContext) => ServicesDialog(
        title: 'All Services',
        services: _allServices,
        categoryNameResolver: _categoryName,
        onSelect: (service) {
          Navigator.pop(dialogContext);
          _onServiceSelected(service);
        },
      ),
    );
  }

  void _showAllBranches() {
    showDialog(
      context: context,
      builder: (dialogContext) => BranchesDialog(
        branches: _branches,
        onSelect: (branch) {
          Navigator.pop(dialogContext);
          _onBranchSelected(branch);
        },
      ),
    );
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

    final isSearching = _searchQuery.trim().isNotEmpty;
    final searchResults = isSearching
        ? _allServices.where((s) => s.serviceName.toLowerCase().contains(_searchQuery.trim().toLowerCase())).toList()
        : <ServiceModel>[];

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: isSearching
                    ? [
                        _buildSectionHeader('Search Results', () {}, showSeeMore: false),
                        const SizedBox(height: 12),
                        searchResults.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'No services found for "${_searchQuery.trim()}"',
                                    style: GoogleFonts.poppins(color: AppColors.brown),
                                  ),
                                ),
                              )
                            : _buildServicesList(searchResults),
                      ]
                    : [
                        _buildSectionHeader('Categories', _showAllCategories),
                        const SizedBox(height: 12),
                        _buildCategoriesRow(),
                        const SizedBox(height: 22),
                        _buildSectionHeader(
                          _selectedCategoryId != null ? _categoryName(_selectedCategoryId!) : 'Services',
                          _showAllServices,
                          showSeeMore: _selectedCategoryId == null,
                        ),
                        const SizedBox(height: 12),
                        _buildServicesList(_displayedServices),
                        const SizedBox(height: 22),
                        _buildSectionHeader('Branches', _showAllBranches),
                        const SizedBox(height: 12),
                        _buildBranchesRow(),
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
                backgroundImage: _profilePicture != null ? MemoryImage(base64Decode(_profilePicture!)) : null,
                child: _profilePicture == null ? Icon(Icons.person, color: AppColors.darkBrown, size: 26) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mapalad Na Araw!', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                    Text(_fullName, style: GoogleFonts.poppins(color: AppColors.lightBrown, fontStyle: FontStyle.italic, fontSize: 12)),
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
          Text('Find a Service', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 19)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(30)),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[500]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeMore, {bool showSeeMore = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w700, fontSize: 22)),
        if (showSeeMore)
          GestureDetector(
            onTap: onSeeMore,
            child: Text('See more', style: GoogleFonts.poppins(color: AppColors.brown, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildCategoriesRow() {
    final visible = _categories.take(3).toList();
    return Row(
      children: visible.map((category) {
        final isSelected = _selectedCategoryId == category.categoryId;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: category != visible.last ? 10 : 0),
            child: GestureDetector(
              onTap: () => _selectCategory(category.categoryId),
              child: Container(
                height: 64,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.brown,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brown.withOpacity(isSelected ? 0.55 : 0.4),
                      blurRadius: isSelected ? 10 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  category.categoryName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServicesList(List<ServiceModel> services) {
    if (services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('No services found.', style: GoogleFonts.poppins(color: AppColors.brown)),
      );
    }

    return Column(
      children: services.map((service) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _onServiceSelected(service),
            child: Container(
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
                        Text(service.serviceName, style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w700, fontSize: 17)),
                        const SizedBox(height: 2),
                        Text(_categoryName(service.categoryId), style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.w600, fontSize: 12.5)),
                        Text('Duration: ${service.duration}', style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.w600, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Text('PHP ${service.price.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.bold, fontSize: 14.5)),
                  const SizedBox(width: 10),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.darkBrown, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBranchesRow() {
    final visible = _branches.take(3).toList();
    return Row(
      children: visible.map((branch) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: branch != visible.last ? 10 : 0),
            child: GestureDetector(
              onTap: () => _onBranchSelected(branch),
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.lightBrown.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brown.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _branchImagePath(branch.branchName) != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              _branchImagePath(branch.branchName)!,
                              width: double.infinity,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.spa, color: AppColors.brown, size: 30),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    branch.branchName.replaceFirst('Mapalad Massage and Spa-', '').replaceFirst('Mapalad Massage and Spa ', ''),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}