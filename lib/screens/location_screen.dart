import 'package:flutter/material.dart';
import 'package:testetrack/core/app_theme.dart';
import 'package:testetrack/services/location_services.dart';
import 'package:testetrack/widgets/app_header.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _isLoading = false;
  String? _error;
  String? _currentLocation;
    
  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    try {
      await _getCurrentLocation();
    } catch (e) {
      // Show troubleshooting dialog if location fails
      if (mounted) {
        _showLocationTroubleshootingDialog(e.toString());
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentLocation = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Unable to get location';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  
  
  Future<void> _refreshLocation() async {
    LocationService.clearCachedPosition();
    await _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'Location',
            showBackButton: true,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Current Location'),
                        const SizedBox(height: 16),
                        _buildCurrentLocationCard(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCurrentLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Your Location',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshLocation,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              )
            else if (_currentLocation != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentLocation!,
                        style: TextStyle(color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text('Location not available'),
          ],
        ),
      ),
    );
  }

  
  
  
  void _showLocationTroubleshootingDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Access Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To use location features, please check:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('• Location services are enabled in device settings'),
            const Text('• GPS is available and has clear signal'),
            const Text('• App has location permission'),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quick fixes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Enable location services in device settings'),
            const Text('2. Grant location permission to this app'),
            const Text('3. Make sure GPS is working'),
            const Text('4. Try again after enabling permissions'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _refreshLocation();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
