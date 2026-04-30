import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Position? _currentPosition;
  static bool _isPermissionGranted = false;
  static bool _usingManualSearch = false; // Flag for manual city search fallback

  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permissions
  static Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  static Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current location with proper error handling
  /// Returns position if permission granted, null if denied
  static Future<Position?> getCurrentLocation() async {
    try {
      debugPrint('Getting location...');
      
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('Location service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them in device settings.');
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('Location permission: $permission');
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('Requested permission: $permission');
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied. Please enable location access.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied. Please enable in app settings.');
      }

      debugPrint('Getting current position...');
      // Get actual position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: false,
      );
      
      debugPrint('Position obtained: ${position.latitude}, ${position.longitude}');

      _currentPosition = position;
      _isPermissionGranted = true;
      _usingManualSearch = false;
      return position;
    } catch (e) {
      _isPermissionGranted = false;
      _usingManualSearch = true;
      throw Exception('Location error: ${e.toString()}');
    }
  }

  /// Get nearby grocery stores/markets based on current location
  /// Integrates with real location data to provide practical shopping options
  static Future<List<Map<String, dynamic>>> getNearbyMarkets() async {
    try {
      final position = await getCurrentLocation();
      
      if (position == null || _usingManualSearch) {
        // Return empty list if using manual search
        return [];
      }

      // Get current location address for context-aware suggestions
      final currentAddress = await getAddressFromCoordinates(position.latitude, position.longitude);
      
      // Return location-based grocery stores and markets
      // This would integrate with Google Places API in production
      return [
        {
          'name': 'Local Farmers Market',
          'type': 'Farmers Market',
          'distance': calculateDistance(position.latitude, position.longitude, position.latitude - 0.01, position.longitude - 0.01).toInt(),
          'address': currentAddress,
          'rating': 4.5,
          'hours': '6:00 AM - 2:00 PM',
          'specialties': ['Fresh Produce', 'Local Products', 'Organic'],
          'phone': '+1 234-567-8901',
          'website': 'www.localfarmersmarket.com',
          'isOpen': _isCurrentlyOpen(),
        },
        {
          'name': 'FreshMart Grocery',
          'type': 'Supermarket',
          'distance': calculateDistance(position.latitude, position.longitude, position.latitude + 0.005, position.longitude + 0.008).toInt(),
          'address': currentAddress,
          'rating': 4.2,
          'hours': '7:00 AM - 10:00 PM',
          'specialties': ['Groceries', 'Dairy', 'Bakery', 'Produce'],
          'phone': '+1 234-567-8902',
          'website': 'www.freshmart.com',
          'isOpen': _isCurrentlyOpen(),
        },
        {
          'name': 'Ethiopian Market',
          'type': 'Specialty Store',
          'distance': calculateDistance(position.latitude, position.longitude, position.latitude - 0.008, position.longitude + 0.012).toInt(),
          'address': currentAddress,
          'rating': 4.7,
          'hours': '8:00 AM - 8:00 PM',
          'specialties': ['Ethiopian Spices', 'Injera', 'Berbere', 'Teff'],
          'phone': '+1 234-567-8903',
          'website': 'www.ethiopianmarket.com',
          'isOpen': _isCurrentlyOpen(),
        },
        {
          'name': 'Whole Foods Market',
          'type': 'Organic Supermarket',
          'distance': calculateDistance(position.latitude, position.longitude, position.latitude + 0.015, position.longitude - 0.005).toInt(),
          'address': currentAddress,
          'rating': 4.3,
          'hours': '7:00 AM - 9:00 PM',
          'specialties': ['Organic Products', 'Fresh Produce', 'Natural Foods'],
          'phone': '+1 234-567-8904',
          'website': 'www.wholefoods.com',
          'isOpen': _isCurrentlyOpen(),
        },
      ];
    } catch (e) {
      return [];
    }
  }

  /// Check if store is currently open
  static bool _isCurrentlyOpen() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 6 && hour < 22; // Open from 6 AM to 10 PM
  }

  /// Get location-based ingredient suggestions
  /// Returns seasonal and regional ingredients available near user
  static Future<List<Map<String, dynamic>>> getLocalIngredients() async {
    try {
      final position = await getCurrentLocation();
      
      if (position == null || _usingManualSearch) {
        // Return general ingredients if using manual search
        return [
          {
            'name': 'Tomatoes',
            'season': 'Available',
            'source': 'Local Farms',
            'price': '\$2.99/lb'
          },
          {
            'name': 'Onions',
            'season': 'Available',
            'source': 'Local Farms',
            'price': '\$1.49/lb'
          },
          {
            'name': 'Garlic',
            'season': 'Available',
            'source': 'Local Farms',
            'price': '\$3.99/lb'
          },
          {
            'name': 'Olive Oil',
            'season': 'Available',
            'source': 'Imported',
            'price': '\$8.99/bottle'
          },
          {
            'name': 'Fresh Herbs',
            'season': 'Available',
            'source': 'Local Garden',
            'price': '\$2.49/bunch'
          },
        ];
      }

      // Get current location for regional suggestions
      final currentAddress = await getAddressFromCoordinates(position.latitude, position.longitude);
      final latitude = position.latitude;
      final month = DateTime.now().month;
      
      // Seasonal ingredients based on month and hemisphere
      List<Map<String, dynamic>> seasonalIngredients = [];
      
      if (latitude > 0) { // Northern hemisphere
        if (month >= 3 && month <= 5) { // Spring
          seasonalIngredients = [
            {'name': 'Asparagus', 'season': 'Spring', 'source': 'Local Farms', 'price': '\$4.99/lb'},
            {'name': 'Spinach', 'season': 'Spring', 'source': 'Local Farms', 'price': '\$2.99/lb'},
            {'name': 'Strawberries', 'season': 'Spring', 'source': 'Local Berry Farms', 'price': '\$5.99/pint'},
            {'name': 'Radishes', 'season': 'Spring', 'source': 'Local Farms', 'price': '\$1.99/bunch'},
          ];
        } else if (month >= 6 && month <= 8) { // Summer
          seasonalIngredients = [
            {'name': 'Tomatoes', 'season': 'Summer', 'source': 'Local Farms', 'price': '\$3.99/lb'},
            {'name': 'Corn', 'season': 'Summer', 'source': 'Local Farms', 'price': '\$0.50/ear'},
            {'name': 'Cucumbers', 'season': 'Summer', 'source': 'Local Farms', 'price': '\$2.49/each'},
            {'name': 'Bell Peppers', 'season': 'Summer', 'source': 'Local Farms', 'price': '\$3.99/lb'},
            {'name': 'Zucchini', 'season': 'Summer', 'source': 'Local Farms', 'price': '\$2.49/each'},
          ];
        } else if (month >= 9 && month <= 11) { // Fall
          seasonalIngredients = [
            {'name': 'Apples', 'season': 'Fall', 'source': 'Local Orchards', 'price': '\$3.99/lb'},
            {'name': 'Pumpkins', 'season': 'Fall', 'source': 'Local Farms', 'price': '\$5.99/each'},
            {'name': 'Sweet Potatoes', 'season': 'Fall', 'source': 'Local Farms', 'price': '\$1.99/lb'},
            {'name': 'Brussels Sprouts', 'season': 'Fall', 'source': 'Local Farms', 'price': '\$4.99/lb'},
          ];
        } else { // Winter
          seasonalIngredients = [
            {'name': 'Kale', 'season': 'Winter', 'source': 'Local Farms', 'price': '\$3.99/bunch'},
            {'name': 'Carrots', 'season': 'Winter', 'source': 'Local Farms', 'price': '\$1.99/lb'},
            {'name': 'Potatoes', 'season': 'Winter', 'source': 'Local Farms', 'price': '\$2.99/bag'},
            {'name': 'Cabbage', 'season': 'Winter', 'source': 'Local Farms', 'price': '\$1.99/head'},
          ];
        }
      } else { // Southern hemisphere (opposite seasons)
        if (month >= 9 && month <= 11) { // Spring in southern hemisphere
          seasonalIngredients = [
            {'name': 'Asparagus', 'season': 'Spring', 'source': 'Local Farms', 'price': '\$4.99/lb'},
            {'name': 'Strawberries', 'season': 'Spring', 'source': 'Local Berry Farms', 'price': '\$5.99/pint'},
          ];
        } else if (month >= 12 || month <= 2) { // Summer in southern hemisphere
          seasonalIngredients = [
            {'name': 'Tomatoes', 'season': 'Summer', 'source': 'Local Farms', 'price': '\$3.99/lb'},
            {'name': 'Corn', 'season': 'Summer', 'source': 'Local Farms', 'price': '\$0.50/ear'},
          ];
        } else if (month >= 3 && month <= 5) { // Fall in southern hemisphere
          seasonalIngredients = [
            {'name': 'Apples', 'season': 'Fall', 'source': 'Local Orchards', 'price': '\$3.99/lb'},
            {'name': 'Pumpkins', 'season': 'Fall', 'source': 'Local Farms', 'price': '\$5.99/each'},
          ];
        } else { // Winter in southern hemisphere
          seasonalIngredients = [
            {'name': 'Kale', 'season': 'Winter', 'source': 'Local Farms', 'price': '\$3.99/bunch'},
            {'name': 'Carrots', 'season': 'Winter', 'source': 'Local Farms', 'price': '\$1.99/lb'},
          ];
        }
      }

      // Add location-specific specialty ingredients
      List<Map<String, dynamic>> locationSpecific = [];
      
      // Check if location suggests specific regional specialties
      if (currentAddress.toLowerCase().contains('ethiopia') || 
          currentAddress.toLowerCase().contains('addis') ||
          currentAddress.toLowerCase().contains('haramaya')) {
        locationSpecific = [
          {'name': 'Berbere Spice', 'season': 'Year-round', 'source': 'Ethiopian Market', 'price': '\$6.99/jar'},
          {'name': 'Teff Flour', 'season': 'Year-round', 'source': 'Ethiopian Market', 'price': '\$8.99/bag'},
          {'name': 'Injera', 'season': 'Fresh Daily', 'source': 'Ethiopian Market', 'price': '\$4.99/pack'},
          {'name': 'Niter Kibbeh', 'season': 'Year-round', 'source': 'Ethiopian Market', 'price': '\$7.99/jar'},
          {'name': 'Mitmita', 'season': 'Year-round', 'source': 'Ethiopian Market', 'price': '\$5.99/packet'},
        ];
      } else if (currentAddress.toLowerCase().contains('italy') || 
                 currentAddress.toLowerCase().contains('rome')) {
        locationSpecific = [
          {'name': 'Prosciutto', 'season': 'Year-round', 'source': 'Italian Deli', 'price': '\$12.99/lb'},
          {'name': 'Parmigiano-Reggiano', 'season': 'Year-round', 'source': 'Italian Market', 'price': '\$16.99/wheel'},
          {'name': 'Basil', 'season': 'Summer', 'source': 'Local Gardens', 'price': '\$2.49/bunch'},
          {'name': 'San Marzano Tomatoes', 'season': 'Summer', 'source': 'Local Farms', 'price': '\$4.99/lb'},
        ];
      }

      // Combine seasonal and location-specific ingredients
      return [...seasonalIngredients, ...locationSpecific];
    } catch (e) {
      return [];
    }
  }

  // Get location stream for real-time updates
  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream();
  }

  // Calculate distance between two coordinates
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Get address from coordinates (reverse geocoding)
  static Future<String> getAddressFromCoordinates(double lat, double lon) async {
    try {
      // Use geocoding to get actual address
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      Placemark place = placemarks[0];
      
      // Build a readable address
      String city = place.locality ?? place.subAdministrativeArea ?? 'Unknown City';
      String country = place.country ?? 'Unknown Country';
      String administrativeArea = place.administrativeArea ?? '';
      
      // If we have a specific city name, use it
      if (city != 'Unknown City') {
        return '$city, $country';
      } else if (administrativeArea.isNotEmpty) {
        return '$administrativeArea, $country';
      } else {
        return 'Location: $country';
      }
    } catch (e) {
      return 'Current Location: ${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
    }
  }

  // Open app settings for location permissions
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Open location settings
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Getters
  static Position? get currentPosition => _currentPosition;
  static bool get isPermissionGranted => _isPermissionGranted;
  static bool get usingManualSearch => _usingManualSearch;

  // Clear cached position
  static void clearCachedPosition() {
    _currentPosition = null;
    _usingManualSearch = false;
  }

  // Get location-based recipe suggestions
  static Future<List<String>> getLocationBasedSuggestions() async {
    try {
      final position = await getCurrentLocation();
      if (position == null || _usingManualSearch) {
        // Return general suggestions if using manual search
        return [
          'Popular recipes',
          'Quick meals',
          'Healthy options',
          'Budget-friendly dishes',
        ];
      }

      // This could integrate with a local restaurant API
      // For now, return some mock suggestions based on location
      final suggestions = [
        'Local restaurants near you',
        'Popular dishes in your area',
        'Regional specialties',
        'Farmers market recipes',
        'Seasonal local ingredients',
      ];

      return suggestions;
    } catch (e) {
      return [];
    }
  }

  // Check if user is in a specific region (for region-specific recipes)
  static bool isInRegion(Position position, String region) {
    // This is a simplified implementation
    // In a real app, you'd have proper geofencing
    switch (region.toLowerCase()) {
      case 'north':
        return position.latitude > 0;
      case 'south':
        return position.latitude < 0;
      case 'east':
        return position.longitude > 0;
      case 'west':
        return position.longitude < 0;
      default:
        return false;
    }
  }
}
