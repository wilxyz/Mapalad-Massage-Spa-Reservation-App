import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/service_model.dart';

class ServicesDialog extends StatelessWidget {
  final String title;
  final List<ServiceModel> services;
  final String Function(String categoryId) categoryNameResolver;
  final void Function(ServiceModel service) onSelect;

  const ServicesDialog({
    super.key,
    required this.title,
    required this.services,
    required this.categoryNameResolver,
    required this.onSelect,
  });

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
                  Text(title, style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w700, fontSize: 21)),
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
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return GestureDetector(
                      onTap: () => onSelect(service),
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
                                  Text(service.serviceName, style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w700, fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text(categoryNameResolver(service.categoryId), style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.w600, fontSize: 12)),
                                  Text('Duration: ${service.duration}', style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.w600, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('PHP ${service.price.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: AppColors.brown, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 8),
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