import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _favoritesKey = 'favorite_recipes';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _searchHistoryKey = 'search_history';
  static const String _profileImageKey = 'profile_image_path';

  // Favorites Management
  static Future<List<String>> getFavoriteRecipeIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey) ?? '[]';
      final List<dynamic> favorites = json.decode(favoritesJson);
      return favorites.cast<String>();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveFavoriteRecipeIds(List<String> recipeIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = json.encode(recipeIds);
      await prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  static Future<void> addFavorite(String recipeId) async {
    final favorites = await getFavoriteRecipeIds();
    if (!favorites.contains(recipeId)) {
      favorites.add(recipeId);
      await saveFavoriteRecipeIds(favorites);
    }
  }

  static Future<void> removeFavorite(String recipeId) async {
    final favorites = await getFavoriteRecipeIds();
    favorites.remove(recipeId);
    await saveFavoriteRecipeIds(favorites);
  }

  static Future<bool> isFavorite(String recipeId) async {
    final favorites = await getFavoriteRecipeIds();
    return favorites.contains(recipeId);
  }

  // User Preferences
  static Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_userPreferencesKey) ?? '{}';
      return json.decode(preferencesJson);
    } catch (e) {
      return {};
    }
  }

  static Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = json.encode(preferences);
      await prefs.setString(_userPreferencesKey, preferencesJson);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  static Future<String> getPreferredCategory() async {
    final preferences = await getUserPreferences();
    return preferences['preferred_category'] ?? 'All';
  }

  static Future<void> setPreferredCategory(String category) async {
    final preferences = await getUserPreferences();
    preferences['preferred_category'] = category;
    await saveUserPreferences(preferences);
  }

  static Future<bool> getDarkMode() async {
    final preferences = await getUserPreferences();
    return preferences['dark_mode'] ?? false;
  }

  static Future<void> setDarkMode(bool isDark) async {
    final preferences = await getUserPreferences();
    preferences['dark_mode'] = isDark;
    await saveUserPreferences(preferences);
  }

  // Search History
  static Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_searchHistoryKey) ?? '[]';
      final List<dynamic> history = json.decode(historyJson);
      return history.cast<String>();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveSearchHistory(List<String> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(history);
      await prefs.setString(_searchHistoryKey, historyJson);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  static Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final history = await getSearchHistory();
    history.remove(query); // Remove if it already exists
    history.insert(0, query); // Add to beginning
    
    // Keep only last 10 searches
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }
    
    await saveSearchHistory(history);
  }

  static Future<void> clearSearchHistory() async {
    await saveSearchHistory([]);
  }

  // Clear all data
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      await prefs.remove(_userPreferencesKey);
      await prefs.remove(_searchHistoryKey);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  // Profile Image Management
  static Future<void> saveProfileImage(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImageKey, imagePath);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  static Future<String?> getProfileImagePath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_profileImageKey);
    } catch (e) {
      return null;
    }
  }

  static Future<void> removeProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileImageKey);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  // Storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    final favorites = await getFavoriteRecipeIds();
    final history = await getSearchHistory();
    final preferences = await getUserPreferences();
    
    return {
      'favorite_count': favorites.length,
      'search_history_count': history.length,
      'preferences_count': preferences.length,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
}
