import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';
import '../models/branch_model.dart';
import '../models/therapist_model.dart';
import '../models/addon_model.dart';
import '../services/home_api_service.dart';

class BookAppointmentFlow extends StatefulWidget {
  final ServiceModel? initialService;
  final BranchModel? initialBranch;

  const BookAppointmentFlow({super.key, this.initialService, this.initialBranch});

  @override
  State<BookAppointmentFlow> createState() => _BookAppointmentFlowState();
}

class _BookAppointmentFlowState extends State<BookAppointmentFlow> {
  static const List<String> _timeSlots = [
    '11:00 AM - 12:00 PM', '12:00 PM - 1:00 PM',
    '1:00 PM - 2:00 PM', '2:00 PM - 3:00 PM',
    '3:00 PM - 4:00 PM', '4:00 PM - 5:00 PM',
    '5:00 PM - 6:00 PM', '6:00 PM - 7:00 PM',
    '7:00 PM - 8:00 PM', '8:00 PM - 9:00 PM',
    '9:00 PM - 10:00 PM', '10:00 PM - 11:00 PM',
  ];

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const Map<String, String> _serviceImages = {
    'Swedish': 'assets/images/swedish_massage.png',
    'Regular Combination': 'assets/images/regular_combination.png',
    'Thai Massage': 'assets/images/thai_massage.png',
    'Customized Massage': 'assets/images/customized_massage.png',
    'Ala Eh! Masahe': 'assets/images/alaeh_masahe.png',
    'Traditional Hilot': 'assets/images/traditional_hilot.png',
    'Deep Tissue': 'assets/images/deep_tissue.png',
    'Foot Reflexology': 'assets/images/foot_reflexology.png',
    'Hand Reflexology': 'assets/images/hand_reflexology.png',
    'Kiddie Massage': 'assets/images/kiddie_massage.png',
    'Pre/Post Natal Therapy': 'assets/images/natal_therapy.png',
    'Post Operation Massage Therapy': 'assets/images/post_operation.png',
    'Sauna': 'assets/images/sauna.png',
    'Basic Footspa': 'assets/images/footspa.png',
    'Whole Body Scrub': 'assets/images/body_scrub.png',
    '15 MINS Head Massage': 'assets/images/head_massage.png',
    '30 MINS Back Massage': 'assets/images/back_massage.png',
  };

  static final RegExp _contactNumberPattern = RegExp(r'^09\d{9}$');

  int _currentStep = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;

  List<CategoryModel> _categories = [];
  List<ServiceModel> _services = [];
  List<BranchModel> _branches = [];
  List<TherapistModel> _therapists = [];
  List<AddOnModel> _addOns = [];

  ServiceModel? _selectedService;
  BranchModel? _selectedBranch;
  TherapistModel? _selectedTherapist;
  bool _anyTherapistChosen = false;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  AddOnModel? _selectedAddOn;
  bool _noAddOnChosen = false;

  final _fullNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  List<String> _takenSlots = [];
  bool _isCheckingAvailability = false;
  String? _bookingId;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.initialService;
    _selectedBranch = widget.initialBranch;
    _currentStep = widget.initialService != null ? 1 : 0;
    _loadInitialData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        HomeApiService.fetchCategories(),
        HomeApiService.fetchServices(),
        HomeApiService.fetchBranches(),
        HomeApiService.fetchTherapists(),
        HomeApiService.fetchAddOns(),
        HomeApiService.fetchCurrentUser(),
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

      final profile = results[5] as Map<String, String>;
      setState(() {
        _categories = results[0] as List<CategoryModel>;
        _services = dedupedServices;
        _branches = dedupedBranches;
        _therapists = results[3] as List<TherapistModel>;
        _addOns = results[4] as List<AddOnModel>;
        _fullNameController.text = profile['fullName'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Could not load booking data. Is the backend running?';
        _isLoading = false;
      });
    }
  }

  String _categoryName(String categoryId) {
    final match = _categories.where((c) => c.categoryId == categoryId);
    return match.isNotEmpty ? match.first.categoryName : '';
  }

  Future<void> _loadTakenSlots() async {
    if (_selectedBranch == null || _selectedDate == null) return;
    setState(() => _isCheckingAvailability = true);
    try {
      final slots = await HomeApiService.fetchTakenSlots(
        branchId: _selectedBranch!.branchId,
        date: _formatDateForApi(_selectedDate!),
        therapistId: _anyTherapistChosen ? null : _selectedTherapist?.uid,
      );
      setState(() {
        _takenSlots = slots;
        if (_selectedTimeSlot != null && _takenSlots.contains(_selectedTimeSlot)) {
          _selectedTimeSlot = null;
        }
        _isCheckingAvailability = false;
      });
    } catch (e) {
      setState(() => _isCheckingAvailability = false);
    }
  }

  String _formatDateForApi(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatDateForDisplay(DateTime date) => '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedService != null;
      case 1:
        return _selectedBranch != null;
      case 2:
        return _selectedTherapist != null || _anyTherapistChosen;
      case 3:
        return _selectedDate != null && _selectedTimeSlot != null;
      case 4:
        return _selectedAddOn != null || _noAddOnChosen;
       case 5:
        return _fullNameController.text.trim().isNotEmpty &&
            _contactNumberPattern.hasMatch(_contactController.text.trim());
      default:
        return true;
    }
  }
  String _validationMessage() {
    if (_currentStep == 5) {
      if (_fullNameController.text.trim().isEmpty) {
        return 'Please enter your full name.';
      }
      if (!_contactNumberPattern.hasMatch(_contactController.text.trim())) {
        return 'Contact number must be exactly 11 digits and start with 09.';
      }
    }
    return 'Please complete this step before continuing.';
  }
  void _goNext() {
    if (!_canProceed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_validationMessage())),
      );
      return;
    }
    if (_currentStep == 5) {
      setState(() => _currentStep = 6);
      return;
    }
    setState(() => _currentStep++);
    if (_currentStep == 3) _loadTakenSlots();
  }

  void _goBack() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _currentStep--);
  }

  Future<void> _confirmBooking() async {
    setState(() => _isSubmitting = true);
    try {
      final bookingId = await HomeApiService.createBooking({
        'serviceId': _selectedService!.serviceId,
        'serviceName': _selectedService!.serviceName,
        'categoryName': _categoryName(_selectedService!.categoryId),
        'duration': _selectedService!.duration,
        'price': _selectedService!.price,
        'branchId': _selectedBranch!.branchId,
        'branchName': _selectedBranch!.branchName,
        'therapistId': _anyTherapistChosen ? null : _selectedTherapist?.uid,
        'therapistName': _anyTherapistChosen ? 'Any Therapist' : _selectedTherapist?.fullName,
        'appointmentDate': _formatDateForApi(_selectedDate!),
        'timeSlot': _selectedTimeSlot,
        'addOnId': _noAddOnChosen ? null : _selectedAddOn?.addOnId,
        'addOnName': _noAddOnChosen ? null : _selectedAddOn?.addOnName,
        'fullName': _fullNameController.text.trim(),
        'contactNumber': _contactController.text.trim(),
        'email': _emailController.text.trim(),
        'specialRequests': _specialRequestsController.text.trim(),
      });
      setState(() {
        _bookingId = bookingId;
        _currentStep = 7;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit booking: $e')),
      );
    }
  }

  Future<void> _printReceipt() async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pwContext) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Mapalad Massage Spa Corporation', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Sa bawat oras ng pahinga-Mapalad Massage and Spa', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 16),
                pw.Divider(),
                _pdfRow('Service', _selectedService?.serviceName ?? ''),
                _pdfRow('Price', 'PHP ${_selectedService?.price.toStringAsFixed(2) ?? ''}'),
                _pdfRow('Branch', _selectedBranch?.branchName ?? ''),
                _pdfRow('Therapist', _anyTherapistChosen ? 'Any Therapist' : (_selectedTherapist?.fullName ?? '')),
                _pdfRow('Date', _selectedDate != null ? _formatDateForDisplay(_selectedDate!) : ''),
                _pdfRow('Time', _selectedTimeSlot ?? ''),
                _pdfRow('Name', _fullNameController.text.trim()),
                _pdfRow('Phone', _contactController.text.trim()),
                _pdfRow('Email', _emailController.text.trim()),
                pw.Divider(),
                if (_bookingId != null) pw.Text('Booking Ref: $_bookingId', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: 'mapalad-booking-receipt.pdf');
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_loadError!, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _loadInitialData, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      _buildHeader(),
                      if (_currentStep <= 6) ...[
                        const SizedBox(height: 20),
                        _buildStepper(),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_stepTitle(), style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 26)),
                          ),
                        ),
                      ],
                      if (_currentStep == 7) ...[
                        const SizedBox(height: 16),
                        Icon(Icons.check_circle_outline, color: AppColors.darkBrown, size: 70),
                        const SizedBox(height: 10),
                        Text('Booking Submitted!', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 24)),
                        Text('You can view the status in the Booking History Page.',
                            style: GoogleFonts.poppins(color: AppColors.brown, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                      const SizedBox(height: 16),
                      Expanded(child: _buildStepBody()),
                      _buildFooter(),
                    ],
                  ),
      ),
    );
  }

  String _stepTitle() {
    switch (_currentStep) {
      case 0: return 'Select Service';
      case 1: return 'Select Branch';
      case 2: return 'Select Therapist';
      case 3: return 'Set Date and Time';
      case 4: return 'Select Add-Ons';
      case 5: return 'Enter Booking Details';
      case 6: return 'Confirm Booking Details';
      default: return '';
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
          Expanded(
            child: Text(
              'Book an Appointment',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final activeStep = _currentStep >= 6 ? 6 : _currentStep;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(11, (i) {
          if (i.isOdd) {
            final leftIndex = (i - 1) ~/ 2;
            final isDone = leftIndex < activeStep;
            return Expanded(
              child: Container(height: 2, color: isDone ? AppColors.darkBrown : AppColors.lightBrown.withOpacity(0.5)),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < activeStep;
          final isCurrent = stepIndex == activeStep;
          return Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone || isCurrent ? AppColors.darkBrown : Colors.white,
              border: Border.all(color: AppColors.darkBrown, width: 1.6),
            ),
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${stepIndex + 1}',
                    style: GoogleFonts.poppins(
                      color: isCurrent ? Colors.white : AppColors.darkBrown,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
          );
        }),
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_currentStep) {
      case 0: return _buildSelectService();
      case 1: return _buildSelectBranch();
      case 2: return _buildSelectTherapist();
      case 3: return _buildSetDateTime();
      case 4: return _buildSelectAddOns();
      case 5: return _buildBookingDetails();
      case 6: return _buildConfirmSummary();
      case 7: return _buildSubmittedSummary();
      default: return const SizedBox.shrink();
    }
  }

  Widget _cardWrapper(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.brown.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: child,
    );
  }

  Widget _optionButton({required Widget child, required bool selected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.brown,
            borderRadius: BorderRadius.circular(16),
            border: selected ? Border.all(color: AppColors.darkBrown, width: 3) : null,
            boxShadow: [BoxShadow(color: AppColors.brown.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Expanded(child: child),
              if (selected) const Icon(Icons.check_circle, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
  Widget _serviceThumbnail(String serviceName) {
    final assetPath = _serviceImages[serviceName];
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 66,
        height: 66,
        color: Colors.white.withOpacity(0.18),
        child: assetPath != null
            ? Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.spa, color: Colors.white, size: 28),
              )
            : const Icon(Icons.spa, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSelectService() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: _cardWrapper(
        Column(
          children: _services.map((service) {
            final selected = _selectedService?.serviceId == service.serviceId;
            return _optionButton(
              selected: selected,
              onTap: () => setState(() => _selectedService = service),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _serviceThumbnail(service.serviceName),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service.serviceName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                        Text(_categoryName(service.categoryId), style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12.5)),
                        Text('Duration: ${service.duration}', style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11.5, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 4),
                        Text('PHP ${service.price.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSelectBranch() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: _cardWrapper(
        Column(
          children: _branches.map((branch) {
            final selected = _selectedBranch?.branchId == branch.branchId;
            return _optionButton(
              selected: selected,
              onTap: () => setState(() => _selectedBranch = branch),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(branch.branchName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                  Text(branch.branchAddress, style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11.5, fontStyle: FontStyle.italic)),
                  Text('Open: 11AM - 11PM', style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11.5, fontStyle: FontStyle.italic)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSelectTherapist() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: _cardWrapper(
        Column(
          children: [
            _optionButton(
              selected: _anyTherapistChosen,
              onTap: () => setState(() {
                _anyTherapistChosen = true;
                _selectedTherapist = null;
              }),
              child: Center(
                child: Text('Any Therapist', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
              ),
            ),
            ..._therapists.map((therapist) {
              final selected = !_anyTherapistChosen && _selectedTherapist?.uid == therapist.uid;
              return _optionButton(
                selected: selected,
                onTap: () => setState(() {
                  _anyTherapistChosen = false;
                  _selectedTherapist = therapist;
                }),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 16, backgroundColor: Colors.white, child: Icon(Icons.person, color: AppColors.brown)),
                    const SizedBox(width: 12),
                    Text(therapist.fullName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSetDateTime() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: _cardWrapper(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Date:', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    _selectedTimeSlot = null;
                  });
                  _loadTakenSlots();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.brown,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.brown.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null ? _formatDateForDisplay(_selectedDate!) : 'mm/dd/yyyy',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Choose Time Slot:', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 15)),
                if (_isCheckingAvailability) ...[
                  const SizedBox(width: 10),
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: _timeSlots.map((slot) {
                final isTaken = _takenSlots.contains(slot);
                final selected = _selectedTimeSlot == slot;
                return GestureDetector(
                  onTap: isTaken ? null : () => setState(() => _selectedTimeSlot = slot),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isTaken ? Colors.grey[300] : (selected ? AppColors.darkBrown : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isTaken ? Colors.grey[400]! : AppColors.darkBrown, width: 1.4),
                      boxShadow: isTaken
                          ? null
                          : [BoxShadow(color: AppColors.brown.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
                    ),
                    child: Text(
                      slot,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: isTaken ? Colors.grey[500] : (selected ? Colors.white : AppColors.darkBrown),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectAddOns() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: _cardWrapper(
        Column(
          children: [
            _optionButton(
              selected: _noAddOnChosen,
              onTap: () => setState(() {
                _noAddOnChosen = true;
                _selectedAddOn = null;
              }),
              child: Row(
                children: [
                  const Icon(Icons.block, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('No Add-Ons', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                ],
              ),
            ),
            ..._addOns.map((addOn) {
              final selected = !_noAddOnChosen && _selectedAddOn?.addOnId == addOn.addOnId;
              return _optionButton(
                selected: selected,
                onTap: () => setState(() {
                  _noAddOnChosen = false;
                  _selectedAddOn = addOn;
                }),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addOn.addOnName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                    Text('Add-Ons', style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12.5)),
                    Text('Duration: ${addOn.duration}', style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11.5, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 4),
                    Text('PHP ${addOn.price.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: _cardWrapper(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Full Name:', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(controller: _fullNameController, decoration: const InputDecoration(hintText: 'Enter Full Name')),
            const SizedBox(height: 14),
            Text('Contact Number:', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: const InputDecoration(hintText: '09XXXXXXXXX'),
            ),
            const SizedBox(height: 14),
            Text('Email (optional):', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Enter Email Address'),
            ),
            const SizedBox(height: 14),
            Text('Special Requests (optional):', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _specialRequestsController,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Enter Special Requests'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return _cardWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/logo.jpg', height: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mapalad Massage Spa Corporation',
                        style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 14)),
                    Text('Sa bawat oras ng pahinga—Mapalad Massage and Spa',
                        style: GoogleFonts.poppins(color: AppColors.lightBrown, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          _summaryRow('Service', _selectedService?.serviceName ?? ''),
          _summaryRow('Price', _selectedService != null ? _selectedService!.price.toStringAsFixed(2) : ''),
          _summaryRow('Branch', _selectedBranch?.branchName ?? ''),
          _summaryRow('Therapist', _anyTherapistChosen ? 'Any Therapist' : (_selectedTherapist?.fullName ?? '')),
          _summaryRow('Date', _selectedDate != null ? _formatDateForDisplay(_selectedDate!) : ''),
          _summaryRow('Time', _selectedTimeSlot ?? ''),
          _summaryRow('Name', _fullNameController.text.trim()),
          _summaryRow('Phone', _contactController.text.trim()),
          _summaryRow('Email', _emailController.text.trim()),
          if (!_noAddOnChosen && _selectedAddOn != null) _summaryRow('Add-On', _selectedAddOn!.addOnName),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: AppColors.lightBrown, fontWeight: FontWeight.w600, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmSummary() {
    return SingleChildScrollView(padding: const EdgeInsets.only(bottom: 20), child: _buildSummaryCard());
  }

  Widget _buildSubmittedSummary() {
    return SingleChildScrollView(padding: const EdgeInsets.only(bottom: 20), child: _buildSummaryCard());
  }

  Widget _pillButton({
  required String label,
  required IconData icon,
  required VoidCallback? onPressed,
  bool outlined = false,
  bool iconLeading = true,
  bool isLoading = false,
}) {
  final textStyle = GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16);

  final content = isLoading
      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
      : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: iconLeading
              ? [Icon(icon, size: 20), const SizedBox(width: 8), Text(label, style: textStyle)]
              : [Text(label, style: textStyle), const SizedBox(width: 8), Icon(icon, size: 20)],
        );

  if (outlined) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkBrown,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: BorderSide(color: AppColors.darkBrown, width: 2.5),
      ),
      child: content,
    );
  }

  return ElevatedButton(onPressed: onPressed, child: content);
}

  Widget _buildFooter() {
    if (_currentStep == 7) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            _pillButton(label: 'Print Transaction', icon: Icons.print, onPressed: _printReceipt, iconLeading: false),
            const SizedBox(height: 10),
            _pillButton(
              label: 'Home',
              icon: Icons.home,
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              outlined: true,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          Expanded(child: _pillButton(label: 'Back', icon: Icons.arrow_back, onPressed: _goBack, outlined: true)),
          const SizedBox(width: 14),
          Expanded(
            child: _currentStep == 6
                ? _pillButton(
                    label: 'Confirm',
                    icon: Icons.arrow_forward,
                    onPressed: _isSubmitting ? null : _confirmBooking,
                    iconLeading: false,
                    isLoading: _isSubmitting,
                  )
                : _pillButton(label: 'Next', icon: Icons.arrow_forward, onPressed: _goNext, iconLeading: false),
          ),
        ],
      ),
    );
  }
}