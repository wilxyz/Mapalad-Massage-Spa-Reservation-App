import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DialogItemData {
  final String title;
  final String? subtitle;
  const DialogItemData({required this.title, this.subtitle});
}

class SelectionListDialog extends StatelessWidget {
  final String title;
  final List<DialogItemData> items;
  final void Function(int index) onSelect;

  const SelectionListDialog({
    super.key,
    required this.title,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.62),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title, style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: item.subtitle != null
                          ? Text(item.subtitle!, style: TextStyle(color: AppColors.brown, fontSize: 12))
                          : null,
                      onTap: () => onSelect(index),
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