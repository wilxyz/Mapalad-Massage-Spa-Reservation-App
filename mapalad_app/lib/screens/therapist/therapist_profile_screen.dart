import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/home_api_service.dart';
import '../../services/therapist_api_service.dart';
import '../login_screen.dart';
import '../notifications_screen.dart';

class TherapistProfileScreen extends StatefulWidget {
  final void Function(int index) onNavigateToTab;

  const TherapistProfileScreen({super.key, required this.onNavigateToTab});

  @override
  State<TherapistProfileScreen> createState() => _TherapistProfileScreenState();
}

class _TherapistProfileScreenState extends State<TherapistProfileScreen> {
  bool _isLoading = true;
  String _fullName = '';
  String _email = '';
  String _role = '';
  String? _profilePicture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String get _displayRole {
    if (_role.isEmpty) return '';
    return _role[0].toUpperCase() + _role.substring(1);
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await HomeApiService.fetchProfile();
      setState(() {
        _fullName = profile['fullName'] as String? ?? '';
        _email = profile['email'] as String? ?? '';
        _role = profile['role'] as String? ?? '';
        _profilePicture = profile['profilePicture'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Do you want to Log Out?',
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
                    _logout(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFE15252),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Log Out',
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
                    'Cancel',
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

  void _openProfileEditDialog() {
    showDialog(
      context: context,
      builder: (_) => _TherapistProfileEditDialog(
        fullName: _fullName,
        email: _email,
        profilePicture: _profilePicture,
        onProfileUpdated: ({String? fullName, String? email, String? profilePicture}) {
          setState(() {
            if (fullName != null) _fullName = fullName;
            if (email != null) _email = email;
            if (profilePicture != null) _profilePicture = profilePicture;
          });
        },
      ),
    );
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.white,
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My Profile',
                    style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 28),
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
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lightBrown, width: 2),
                  color: const Color(0xFFF0F0F0),
                  image: _profilePicture != null
                      ? DecorationImage(image: MemoryImage(base64Decode(_profilePicture!)), fit: BoxFit.cover)
                      : null,
                ),
                child: _profilePicture == null
                    ? Icon(Icons.person, size: 56, color: AppColors.lightBrown)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _fullName,
                style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                _displayRole,
                style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                _email,
                style: GoogleFonts.poppins(color: AppColors.lightBrown, fontStyle: FontStyle.italic, fontSize: 13),
              ),
            ),
            const SizedBox(height: 28),
            _menuButton(icon: Icons.person_outline, label: 'My Profile', onTap: _openProfileEditDialog),
            const SizedBox(height: 14),
            _menuButton(
              icon: Icons.calendar_month_outlined,
              label: 'My Availability',
              onTap: () => widget.onNavigateToTab(1),
            ),
            const SizedBox(height: 30),
            _menuButton(icon: Icons.logout, label: 'Log Out', onTap: _confirmLogout),
          ],
        ),
      ),
    );
  }

  Widget _menuButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          side: BorderSide(color: AppColors.darkBrown, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.darkBrown),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.darkBrown),
          ],
        ),
      ),
    );
  }
}

/// Shared "card" chrome matching AuthScaffold's inner card (logo row + title),
/// used for the OTP and Create Password popups so they visually match
/// otp_screen.dart / create_password_screen.dart even though they're dialogs.
class _TherapistAuthDialogCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _TherapistAuthDialogCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.lightBrown, width: 2),
                    image: const DecorationImage(image: AssetImage('assets/images/logo.jpg'), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mapalad Massage Spa Corporation',
                        style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sa bawat oras ng pahinga—Mapalad Massage and Spa',
                        style: TextStyle(color: AppColors.lightBrown, fontStyle: FontStyle.italic, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.bold, fontSize: 23)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _TherapistOtpDialog extends StatefulWidget {
  final String email;
  final String purpose;
  final Future<void> Function() onResend;

  const _TherapistOtpDialog({required this.email, required this.purpose, required this.onResend});

  @override
  State<_TherapistOtpDialog> createState() => _TherapistOtpDialogState();
}

class _TherapistOtpDialogState extends State<_TherapistOtpDialog> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showError('Enter the 6-digit code');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = await HomeApiService.verifyProfileOtp(
        email: widget.email,
        otp: otp,
        purpose: widget.purpose,
      );
      if (!mounted) return;
      Navigator.pop(context, token);
    } catch (e) {
      _showError('Invalid or expired OTP');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await widget.onResend();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A new code was sent to your email')));
    } catch (_) {}
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.darkBrown),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 44,
      height: 50,
      textStyle: TextStyle(fontSize: 20, color: AppColors.darkBrown, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(12)),
    );

    return _TherapistAuthDialogCard(
      title: 'Verify OTP',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter the 6-digit code sent to\n${widget.email}',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.brown, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Pinput(
            length: 6,
            controller: _otpController,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(border: Border.all(color: AppColors.brown, width: 2)),
            ),
          ),
          const SizedBox(height: 14),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _verify, child: const Text('Verify'))),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _resend,
            child: Text("Didn't receive a code? Resend", style: TextStyle(color: AppColors.lightBrown)),
          ),
        ],
      ),
    );
  }
}

class _TherapistCreatePasswordDialog extends StatefulWidget {
  final String verificationToken;

  const _TherapistCreatePasswordDialog({required this.verificationToken});

  @override
  State<_TherapistCreatePasswordDialog> createState() => _TherapistCreatePasswordDialogState();
}

class _TherapistCreatePasswordDialogState extends State<_TherapistCreatePasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await HomeApiService.setNewPassword(
        newPassword: password,
        verificationToken: widget.verificationToken,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Could not update password. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.darkBrown),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _TherapistAuthDialogCard(
      title: 'Create Password',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set a new password for your account.', style: TextStyle(color: AppColors.brown, fontSize: 13)),
          const SizedBox(height: 12),
          Text('New Password:', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Confirm Password:', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(controller: _confirmController, obscureText: _obscure),
          const SizedBox(height: 14),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submit, child: const Text('Save Password'))),
        ],
      ),
    );
  }
}

class _TherapistProfileEditDialog extends StatefulWidget {
  final String fullName;
  final String email;
  final String? profilePicture;
  final void Function({String? fullName, String? email, String? profilePicture}) onProfileUpdated;

  const _TherapistProfileEditDialog({
    required this.fullName,
    required this.email,
    required this.profilePicture,
    required this.onProfileUpdated,
  });

  @override
  State<_TherapistProfileEditDialog> createState() => _TherapistProfileEditDialogState();
}

class _TherapistProfileEditDialogState extends State<_TherapistProfileEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  String? _profilePicture;

  bool _nameEditable = false;
  bool _emailEditable = false;
  bool _isProcessingName = false;
  bool _isProcessingEmail = false;
  bool _isProcessingPassword = false;
  bool _isProcessingAvatar = false;
  String? _currentEmailVerificationToken;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fullName);
    _emailController = TextEditingController(text: widget.email);
    _profilePicture = widget.profilePicture;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _showOtpDialog({required String email, required String purpose}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _TherapistOtpDialog(
        email: email,
        purpose: purpose,
        onResend: () => HomeApiService.requestProfileOtp(
          purpose: purpose,
          newEmail: purpose == 'change_email_new' ? email : null,
          verificationToken: purpose == 'change_email_new' ? _currentEmailVerificationToken : null,
        ),
      ),
    );
  }

  Future<void> _pickAndSaveAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );
    if (picked == null) return;

    setState(() => _isProcessingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);
      await HomeApiService.updateProfile(profilePicture: base64Image);
      setState(() => _profilePicture = base64Image);
      widget.onProfileUpdated(profilePicture: base64Image);
      _showSnack('Profile picture has been updated!');
    } catch (e) {
      _showSnack('Could not update profile picture. Please try again.');
    } finally {
      if (mounted) setState(() => _isProcessingAvatar = false);
    }
  }

  Future<void> _handleNameButton() async {
    if (!_nameEditable) {
      setState(() => _nameEditable = true);
      return;
    }
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _showSnack('Name cannot be empty.');
      return;
    }
    setState(() => _isProcessingName = true);
    try {
      await HomeApiService.updateProfile(fullName: newName);
      setState(() => _nameEditable = false);
      widget.onProfileUpdated(fullName: newName);
      _showSnack('Name has been updated!');
    } catch (e) {
      _showSnack('Could not update name. Please try again.');
    } finally {
      if (mounted) setState(() => _isProcessingName = false);
    }
  }

  Future<void> _handleEmailButton() async {
    if (!_emailEditable) {
      setState(() => _isProcessingEmail = true);
      try {
        await HomeApiService.requestProfileOtp(purpose: 'change_email_current');
      } catch (e) {
        _showSnack('Could not send OTP. Please try again.');
        setState(() => _isProcessingEmail = false);
        return;
      }
      setState(() => _isProcessingEmail = false);
      if (!mounted) return;
      final currentVerifiedToken = await _showOtpDialog(email: widget.email, purpose: 'change_email_current');
      if (currentVerifiedToken == null) return;
      setState(() {
        _emailEditable = true;
        _currentEmailVerificationToken = currentVerifiedToken;
      });
      return;
    }

    final newEmail = _emailController.text.trim();
    if (newEmail.isEmpty || !newEmail.contains('@')) {
      _showSnack('Enter a valid email address.');
      return;
    }
    if (newEmail == widget.email) {
      setState(() => _emailEditable = false);
      return;
    }

    setState(() => _isProcessingEmail = true);
    try {
      await HomeApiService.requestProfileOtp(
        purpose: 'change_email_new',
        newEmail: newEmail,
        verificationToken: _currentEmailVerificationToken,
      );
    } catch (e) {
      _showSnack('Could not send OTP to the new email. Please try again.');
      setState(() => _isProcessingEmail = false);
      return;
    }
    setState(() => _isProcessingEmail = false);
    if (!mounted) return;
    final newEmailVerifiedToken = await _showOtpDialog(email: newEmail, purpose: 'change_email_new');
    if (newEmailVerifiedToken == null) return;

    setState(() => _isProcessingEmail = true);
    try {
      await HomeApiService.updateProfile(email: newEmail, verificationToken: newEmailVerifiedToken);
      setState(() {
        _emailEditable = false;
        _currentEmailVerificationToken = null;
      });
      widget.onProfileUpdated(email: newEmail);
      _showSnack('Email has been updated!');
    } catch (e) {
      _showSnack('Could not update email. Please try again.');
    } finally {
      if (mounted) setState(() => _isProcessingEmail = false);
    }
  }

  Future<void> _startChangePassword() async {
    setState(() => _isProcessingPassword = true);
    try {
      await HomeApiService.requestProfileOtp(purpose: 'change_password');
    } catch (e) {
      _showSnack('Could not send OTP. Please try again.');
      setState(() => _isProcessingPassword = false);
      return;
    }
    setState(() => _isProcessingPassword = false);
    if (!mounted) return;
    final token = await _showOtpDialog(email: widget.email, purpose: 'change_password');
    if (token == null) return;
    if (!mounted) return;
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _TherapistCreatePasswordDialog(verificationToken: token),
    );
    if (success == true) {
      _showSnack('Password has been updated!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My Profile',
                    style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: AppColors.darkBrown),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.lightBrown, width: 2),
                      image: _profilePicture != null
                          ? DecorationImage(image: MemoryImage(base64Decode(_profilePicture!)), fit: BoxFit.cover)
                          : null,
                      color: const Color(0xFFF0F0F0),
                    ),
                    child: _profilePicture == null
                        ? Icon(Icons.person, size: 56, color: AppColors.lightBrown)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isProcessingAvatar ? null : _pickAndSaveAvatar,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: _isProcessingAvatar
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(Icons.edit, size: 16, color: AppColors.darkBrown),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Full Name:', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: TextField(controller: _nameController, enabled: _nameEditable)),
                const SizedBox(width: 8),
                _isProcessingName
                    ? const SizedBox(width: 60, height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                    : ElevatedButton(
                        onPressed: _handleNameButton,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(70, 46),
                          backgroundColor: AppColors.darkBrown,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(_nameEditable ? 'Save' : 'Edit'),
                      ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Email:', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: TextField(controller: _emailController, enabled: _emailEditable)),
                const SizedBox(width: 8),
                _isProcessingEmail
                    ? const SizedBox(width: 60, height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                    : ElevatedButton(
                        onPressed: _handleEmailButton,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(70, 46),
                          backgroundColor: AppColors.darkBrown,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(_emailEditable ? 'Save' : 'Edit'),
                      ),
              ],
            ),
            const SizedBox(height: 20),
            _isProcessingPassword
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _startChangePassword, child: const Text('Change Password')),
          ],
        ),
      ),
    );
  }
}