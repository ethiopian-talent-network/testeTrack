import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick image from camera with proper permission handling
  /// Returns the image path if successful, null if cancelled or denied
  /// Handles three permission states: Granted, Denied, Permanently Denied
  static Future<String?> pickImageFromCamera({required BuildContext context}) async {
    try {
      // Check camera permission
      final permissionResult = await _requestCameraPermission(context);
      
      if (!(permissionResult['granted'] ?? false)) {
        return null;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        return image.path;
      }
      return null;
    } catch (e) {
      // Don't throw exception, just return null for user cancellation
      debugPrint('Camera image pick failed: $e');
      return null;
    }
  }

  
  /// Request camera permission with proper handling
  /// Returns a map with 'granted' boolean and 'permanentlyDenied' boolean
  static Future<Map<String, bool>> _requestCameraPermission(BuildContext context) async {
    if (kIsWeb) return {'granted': true, 'permanentlyDenied': false};

    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      return {'granted': true, 'permanentlyDenied': false};
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      
      if (result.isGranted) {
        return {'granted': true, 'permanentlyDenied': false};
      } else if (result.isDenied) {
        // Show user-friendly snackbar explaining why feature is unavailable
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Camera permission was denied. You cannot capture photos without granting camera access.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => _openAppSettings(),
              ),
            ),
          );
        }
        return {'granted': false, 'permanentlyDenied': false};
      }
    }

    if (status.isPermanentlyDenied) {
      // Provide shortcut to device settings
      if (context.mounted) {
        _showPermanentlyDeniedDialog(
          context,
          'Camera Permission',
          'Camera permission is permanently denied. Please enable it in app settings to capture photos of your recipes.',
        );
      }
      return {'granted': false, 'permanentlyDenied': true};
    }

    return {'granted': false, 'permanentlyDenied': false};
  }

  
  /// Show dialog for permanently denied permissions with settings shortcut
  static void _showPermanentlyDeniedDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Open app settings
  static Future<void> _openAppSettings() async {
    // TODO: Implement proper app settings opening
    // For now, this is a no-op as permission_handler API has changed
  }

  static Future<void> openAppSettings() async {
    // TODO: Implement proper app settings opening
    // For now, this is a no-op as permission_handler API has changed
  }

  static String getPermissionExplanation(String permission) {
    switch (permission) {
      case 'camera':
        return 'Camera permission is needed to take photos of your recipes. This allows you to document your cooking process and share your creations.';
      default:
        return 'This permission is needed for the app to function properly.';
    }
  }

  static bool isPermissionRequired(String permission) {
    if (kIsWeb) return false;
    
    switch (permission) {
      case 'camera':
        return true;
      default:
        return false;
    }
  }
}
