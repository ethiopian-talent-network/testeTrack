import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../data/recipe_service.dart';
import '../services/storage_service.dart';

class RecipeProvider extends ChangeNotifier {
  List<Recipe> _recipes = [];
  List<Recipe> _favoriteRecipes = [];
  List<Recipe> _filteredRecipes = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Getters
  List<Recipe> get recipes => _recipes;
  List<Recipe> get favoriteRecipes => _favoriteRecipes;
  List<Recipe> get filteredRecipes => _filteredRecipes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Initialize recipes
  Future<void> initializeRecipes() async {
    await loadRecipes();
    await loadFavorites();
  }

  // Load all recipes
  Future<void> loadRecipes() async {
    _setLoading(true);
    try {
      final recipes = await RecipeService.getAllRecipes();
      _recipes = recipes;
      _filteredRecipes = recipes; // Initialize filtered recipes with all recipes
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Load favorite recipes
  Future<void> loadFavorites() async {
    try {
      final favorites = await RecipeService.getFavoriteRecipes();
      _favoriteRecipes = favorites;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Enhanced search and filter recipes with ranking
  void searchRecipes(String query, {String? category}) {
    _searchQuery = query;
    if (category != null) {
      _selectedCategory = category;
    }
    
    // Filter locally for instant results
    List<Recipe> results = _recipes;
    
    // Filter by category first
    if (_selectedCategory != 'All') {
      results = results.where((recipe) => recipe.category == _selectedCategory).toList();
    }
    
    // Enhanced search with ranking
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      List<Recipe> searchResults = [];
      
      for (Recipe recipe in results) {
        double score = 0;
        
        // Title exact match gets highest score
        if (recipe.title.toLowerCase() == lowerQuery) {
          score += 100;
        }
        // Title starts with query gets high score
        else if (recipe.title.toLowerCase().startsWith(lowerQuery)) {
          score += 80;
        }
        // Title contains query gets medium score
        else if (recipe.title.toLowerCase().contains(lowerQuery)) {
          score += 60;
        }
        
        // Category match gets bonus
        if (recipe.category.toLowerCase().contains(lowerQuery)) {
          score += 30;
        }
        
        // Ingredient matches get points
        int ingredientMatches = recipe.ingredients.where((ing) => 
          ing.toLowerCase().contains(lowerQuery)
        ).length;
        score += ingredientMatches * 10;
        
        // Add to results if it has any match
        if (score > 0) {
          searchResults.add(recipe);
          // Store score for sorting (we'll sort by score descending)
        }
      }
      
      // Sort by score (highest first) to get most relevant results
      searchResults.sort((a, b) {
        double scoreA = _calculateSearchScore(a, lowerQuery);
        double scoreB = _calculateSearchScore(b, lowerQuery);
        return scoreB.compareTo(scoreA);
      });
      
      results = searchResults;
    }
    
    _filteredRecipes = results;
    _error = null;
    notifyListeners();
    
    // Add to search history asynchronously (don't block the search)
    if (_searchQuery.isNotEmpty && _searchQuery.length >= 1) {
      StorageService.addToSearchHistory(_searchQuery).catchError((e) {
        // Ignore errors from search history
      });
    }
  }
  
  // Helper method to calculate search score for sorting
  double _calculateSearchScore(Recipe recipe, String query) {
    double score = 0;
    
    // Title exact match
    if (recipe.title.toLowerCase() == query) score += 100;
    // Title starts with query
    else if (recipe.title.toLowerCase().startsWith(query)) score += 80;
    // Title contains query
    else if (recipe.title.toLowerCase().contains(query)) score += 60;
    
    // Category match
    if (recipe.category.toLowerCase().contains(query)) score += 30;
    
    // Ingredient matches
    int ingredientMatches = recipe.ingredients.where((ing) => 
      ing.toLowerCase().contains(query)
    ).length;
    score += ingredientMatches * 10;
    
    return score;
  }

  // Toggle favorite status
  Future<void> toggleFavorite(Recipe recipe) async {
    try {
      await RecipeService.toggleFavorite(recipe);
      await loadFavorites();
      
      // Show feedback in UI could be handled here
      final isFavorite = await RecipeService.isFavorite(recipe);
      if (isFavorite) {
        // Recipe added to favorites
      } else {
        // Recipe removed from favorites
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Check if recipe is favorite
  Future<bool> isFavorite(Recipe recipe) async {
    try {
      return await RecipeService.isFavorite(recipe);
    } catch (e) {
      return false;
    }
  }

  // Add new recipe
  Future<void> addRecipe(Recipe recipe) async {
    _setLoading(true);
    try {
      // Add recipe to local list immediately for instant UI update
      _recipes.insert(0, recipe); // Add to beginning of list
      _filteredRecipes.insert(0, recipe); // Add to filtered list too
      
      // Add to storage and favorites
      await StorageService.addFavorite(recipe.id);
      await RecipeService.saveLocalRecipe(recipe); // Save to local storage
      
      // Re-apply current search/filter to include new recipe
      searchRecipes(_searchQuery, category: _selectedCategory);
      
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset filters
  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _filteredRecipes = List.from(_recipes); // Create a copy to avoid reference issues
    notifyListeners();
  }

  // Get recipes by category
  List<Recipe> getRecipesByCategory(String category) {
    if (category == 'All') return _recipes;
    return _recipes.where((recipe) => recipe.category == category).toList();
  }

  // Get recipe statistics
  Map<String, dynamic> getStatistics() {
    return {
      'total_recipes': _recipes.length,
      'favorite_count': _favoriteRecipes.length,
      'categories': _recipes.map((r) => r.category).toSet().length,
      'average_calories': _recipes.isEmpty ? 0 : 
          _recipes.map((r) => r.calories).reduce((a, b) => a + b) / _recipes.length,
    };
  }
}
