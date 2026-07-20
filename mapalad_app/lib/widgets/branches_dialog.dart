import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/branch_model.dart';

class BranchesDialog extends StatelessWidget {
  final List<BranchModel> branches;
  final void Function(BranchModel branch) onSelect;

  const BranchesDialog({super.key, required this.branches, required this.onSelect});

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
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('All Branches', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w700, fontSize: 21)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: AppColors.darkBrown, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: branches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    return GestureDetector(
                      onTap: () => onSelect(branch),
                      child: Container(
                        padding: const EdgeInsets.all(10),
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.lightBrown.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _branchImagePath(branch.branchName) != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        _branchImagePath(branch.branchName)!,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(Icons.spa, color: AppColors.brown, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    branch.branchName
                                        .replaceFirst('Mapalad Massage and Spa-', '')
                                        .replaceFirst('Mapalad Massage and Spa ', ''),
                                    style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                  Text('Opens 11AM – 11PM', style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, fontSize: 11.5)),
                                  const SizedBox(height: 3),
                                  Text(branch.branchAddress, style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w600, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: AppColors.darkBrown, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}