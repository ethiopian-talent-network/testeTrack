import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:testetrack/core/app_theme.dart';
import 'package:testetrack/models/recipe.dart';
import 'package:testetrack/providers/recipe_provider.dart';
import 'package:testetrack/providers/theme_provider.dart';
import 'package:testetrack/widgets/recipe_card.dart';
import 'package:testetrack/widgets/search_bar.dart';
import 'package:testetrack/widgets/category_filter.dart';
import 'package:testetrack/widgets/loading_widget.dart';
import 'package:testetrack/widgets/error_widget.dart';
import 'package:testetrack/utils/responsive_helper.dart';
import 'package:testetrack/screens/profile_screen.dart';
import 'package:testetrack/screens/location_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().initializeRecipes();
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  void _performSearch() {
    // Cancel previous timer
    _searchTimer?.cancel();

    // Set new timer for debounced search
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<RecipeProvider>().searchRecipes(_searchQuery, category: _selectedCategory);
    });
  }

  void _performImmediateSearch() {
    _searchTimer?.cancel();
    context.read<RecipeProvider>().searchRecipes(_searchQuery, category: _selectedCategory);
  }


  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final filteredRecipes = recipeProvider.filteredRecipes;
    final allRecipes = recipeProvider.recipes;

    return Scaffold(
      body: Column(
        children: [
          // Clean Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Icon(Icons.restaurant_menu, color: AppTheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'TasteTrack',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.dark_mode_outlined,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  onPressed: () {
                    context.read<ThemeProvider>().toggleTheme();
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.location_on_outlined, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LocationScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What would you like to cook?",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${allRecipes.length} recipes available",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                RecipeSearchBar(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    // Perform search immediately as user types
                    _performSearch();
                  },
                  onSubmitted: (value) {
                    _performSearch();
                  },
                ),
              ],
            ),
          ),

          // Categories Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Categories",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                CategoryFilter(
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                    _performSearch();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Results Section
          Expanded(
            child: _buildResultsSection(recipeProvider, filteredRecipes, allRecipes),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(RecipeProvider recipeProvider, List<Recipe> filteredRecipes, List<Recipe> allRecipes) {
    // Only show loading during initial load, not during search
    if (recipeProvider.isLoading && allRecipes.isEmpty) {
      return const LoadingWidget(message: 'Loading recipes...');
    }

    if (recipeProvider.error != null && allRecipes.isEmpty) {
      return NetworkErrorWidget(
        onRetry: () => recipeProvider.initializeRecipes(),
        customMessage: recipeProvider.error,
      );
    }

    if (filteredRecipes.isEmpty && allRecipes.isNotEmpty) {
      return DataNotFoundErrorWidget(
        onRefresh: () {
          setState(() {
            _searchQuery = '';
            _selectedCategory = 'All';
          });
          recipeProvider.resetFilters();
        },
        customMessage: 'No recipes found. Try adjusting your search or filters.',
      );
    }

    if (allRecipes.isEmpty) {
      return DataNotFoundErrorWidget(
        onRefresh: () => recipeProvider.initializeRecipes(),
        customMessage: 'No recipes available. Please try again later.',
      );
    }

    return Column(
      children: [
        Padding(
          padding: ResponsiveHelper.getScreenPadding(context).copyWith(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recipes",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${filteredRecipes.length} results",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildRecipeGrid(filteredRecipes),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const DataNotFoundErrorWidget(
      customMessage: 'No recipes found. Try adjusting your search or filters.',
    );
  }

  Widget _buildRecipeGrid(List recipes) {
    return Padding(
      padding: ResponsiveHelper.getScreenPadding(context).copyWith(
        bottom: 16, // Reduced bottom padding
      ),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveHelper.getGridColumns(context),
          childAspectRatio: ResponsiveHelper.getCardAspectRatio(context),
          crossAxisSpacing: ResponsiveHelper.getSpacing(context),
          mainAxisSpacing: ResponsiveHelper.getSpacing(context),
        ),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          return RecipeCard(recipes[index]);
        },
      ),
    );
  }
}
