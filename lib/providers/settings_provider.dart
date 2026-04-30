import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _darkMode = false;
  String _preferredCategory = 'All';
  Map<String, dynamic> _storageStats = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get darkMode => _darkMode;
  String get preferredCategory => _preferredCategory;
  Map<String, dynamic> get storageStats => _storageStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load settings
  Future<void> loadSettings() async {
    _setLoading(true);
    try {
      final darkMode = await StorageService.getDarkMode();
      final preferredCategory = await StorageService.getPreferredCategory();
      final stats = await StorageService.getStorageStats();

      _darkMode = darkMode;
      _preferredCategory = preferredCategory;
      _storageStats = stats;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Update dark mode
  Future<void> updateDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    
    try {
      await StorageService.setDarkMode(value);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update preferred category
  Future<void> updatePreferredCategory(String category) async {
    _preferredCategory = category;
    notifyListeners();
    
    try {
      await StorageService.setPreferredCategory(category);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    _setLoading(true);
    try {
      await StorageService.clearAllData();
      await loadSettings(); // Reload settings after clearing
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Clear search history
  Future<void> clearSearchHistory() async {
    _setLoading(true);
    try {
      await StorageService.clearSearchHistory();
      await loadSettings(); // Reload stats after clearing
      _error = null;
    } catch (e) {
      _error = e.toString();
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
}
