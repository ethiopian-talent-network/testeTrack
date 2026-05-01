import 'package:flutter/material.dart';
import 'package:testetrack/core/app_theme.dart';
import 'package:testetrack/data/recipe_service.dart';
import 'package:testetrack/models/recipe.dart';
import 'package:testetrack/widgets/recipe_card.dart';
import 'package:testetrack/widgets/app_header.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Recipe> _favoriteRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await RecipeService.getFavoriteRecipes();
      setState(() {
        _favoriteRecipes = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(title: 'My Favorites'),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _favoriteRecipes.isEmpty
                    ? _buildEmptyState(context)
                    : _buildFavoritesGrid(context, _favoriteRecipes),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No favorites yet',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start adding recipes to your favorites to see them here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesGrid(BuildContext context, List favorites) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          return RecipeCard(favorites[index]);
        },
      ),
    );
  }
}
