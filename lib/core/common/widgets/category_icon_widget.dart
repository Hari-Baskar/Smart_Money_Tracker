import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';

class CategoryIconWidget extends StatelessWidget {
  final String categoryName;
  final String? emoji;
  final Color color;
  final double size;

  const CategoryIconWidget({
    super.key,
    required this.categoryName,
    this.emoji,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (emoji != null && emoji!.isNotEmpty) {
      return Center(
        child: Text(
          emoji!,
          style: TextStyle(
            fontSize: size,
          ),
        ),
      );
    }

    final isDefault = [
      'food', 'travel', 'shopping', 'bills', 'groceries', 
      'entertainment', 'health', 'investment', 'salary', 
      'other', 'unknown'
    ].contains(categoryName.toLowerCase());

    if (!isDefault && categoryName.isNotEmpty) {
      return Center(
        child: Text(
          categoryName[0].toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.8,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Icon(
      AppColors.getCategoryIcon(categoryName),
      color: color,
      size: size,
    );
  }
}
