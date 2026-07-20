import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/category_model.dart';

class CategoriesDialog extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final void Function(CategoryModel category) onSelect;

  const CategoriesDialog({
    super.key,
    required this.categories,
    required this.onSelect,
    this.selectedCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('All Categories', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w700, fontSize: 21)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: AppColors.darkBrown, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category.categoryId == selectedCategoryId;
                    return GestureDetector(
                      onTap: () => onSelect(category),
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
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