import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class ApiService {
  static const String _baseUrl = 'https://api.spoonacular.com';
  static const String _apiKey = 'YOUR_API_KEY'; // Replace with actual API key
  
  // For demo purposes, we'll use a free recipe API
  static const String _freeApiUrl = 'https://www.themealdb.com/api/json/v1/1';

  static Future<List<Recipe>> fetchRecipes({String category = ''}) async {
    try {
      final String url = category.isEmpty 
          ? '$_freeApiUrl/search.php?s='
          : '$_freeApiUrl/filter.php?c=$category';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return _parseRecipes(data);
      } else {
        throw Exception('Failed to load recipes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Recipe> fetchRecipeDetails(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_freeApiUrl/lookup.php?i=$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return _parseRecipeDetails(data['meals'][0]);
        }
        throw Exception('Recipe not found');
      } else {
        throw Exception('Failed to load recipe details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_freeApiUrl/search.php?s=$query'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return _parseRecipes(data);
      } else {
        throw Exception('Failed to search recipes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static List<Recipe> _parseRecipes(Map<String, dynamic> data) {
    List<Recipe> recipes = [];
    
    if (data['meals'] != null) {
      for (var meal in data['meals']) {
        recipes.add(_parseRecipeFromApi(meal));
      }
    }
    
    return recipes;
  }

  static Recipe _parseRecipeFromApi(Map<String, dynamic> meal) {
    return Recipe(
      id: meal['idMeal'] ?? '',
      title: meal['strMeal'] ?? 'Unknown Recipe',
      imageUrl: meal['strMealThumb'] ?? '',
      duration: '${15 + ((meal['idMeal']?.hashCode.abs() ?? 0) % 30)} min',
      complexity: _getComplexity(meal['strMeal'] ?? ''),
      category: _mapCategory(meal['strCategory'] ?? ''),
      ingredients: _parseIngredients(meal),
      instructions: _parseInstructions(meal['strInstructions'] ?? ''),
      servings: 4,
      calories: 200 + ((meal['idMeal']?.hashCode.abs() ?? 0) % 300),
    );
  }

  static Recipe _parseRecipeDetails(Map<String, dynamic> meal) {
    return Recipe(
      id: meal['idMeal'] ?? '',
      title: meal['strMeal'] ?? 'Unknown Recipe',
      imageUrl: meal['strMealThumb'] ?? '',
      duration: '${15 + ((meal['idMeal']?.hashCode.abs() ?? 0) % 30)} min',
      complexity: _getComplexity(meal['strMeal'] ?? ''),
      category: _mapCategory(meal['strCategory'] ?? ''),
      ingredients: _parseIngredients(meal),
      instructions: _parseInstructions(meal['strInstructions'] ?? ''),
      servings: 4,
      calories: 200 + ((meal['idMeal']?.hashCode.abs() ?? 0) % 300),
    );
  }

  static List<String> _parseIngredients(Map<String, dynamic> meal) {
    List<String> ingredients = [];
    
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'];
      final measure = meal['strMeasure$i'];
      
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        final fullIngredient = measure != null && measure.toString().trim().isNotEmpty
            ? '$measure $ingredient'
            : ingredient;
        ingredients.add(fullIngredient);
      }
    }
    
    return ingredients.isEmpty ? ['Ingredients not available'] : ingredients;
  }

  static List<String> _parseInstructions(String instructions) {
    if (instructions.trim().isEmpty) {
      return ['Instructions not available'];
    }
    
    return instructions
        .split('\r\n')
        .where((step) => step.trim().isNotEmpty)
        .map((step) => step.trim())
        .toList();
  }

  static String _getComplexity(String mealName) {
    final name = mealName.toLowerCase();
    if (name.contains('simple') || name.contains('easy')) return 'Simple';
    if (name.contains('complex') || name.contains('difficult')) return 'Hard';
    return 'Medium';
  }

  static String _mapCategory(String category) {
    switch (category.toLowerCase()) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'dessert':
        return 'Dessert';
      case 'snack':
        return 'Snack';
      default:
        return 'Lunch';
    }
  }
}
