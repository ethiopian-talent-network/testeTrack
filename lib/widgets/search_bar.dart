import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class RecipeSearchBar extends StatelessWidget {
  final Function(String) onChanged;
  final Function(String)? onSubmitted;

  const RecipeSearchBar({
    super.key,
    required this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.searchBoxDecoration,
      child: TextField(
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: const InputDecoration(
          hintText: 'Search recipes...',
          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
    );
  }
}