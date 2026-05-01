import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/app_theme.dart';
import '../services/storage_service.dart';
import '../services/image_service.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Food Lover';
  String _userEmail = 'food.lover@email.com';
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    // Initialize settings when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
      _loadProfileImage();
    });
  }

  Future<void> _loadProfileImage() async {
    final imagePath = await StorageService.getProfileImagePath();
    debugPrint('Loading profile image: $imagePath');
    if (mounted) {
      setState(() {
        _profileImagePath = imagePath;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    // Check camera permission
    final cameraStatus = await Permission.camera.status;
    
    if (cameraStatus.isDenied) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required to take a photo')),
          );
        }
        return;
      }
    } else if (cameraStatus.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable camera permission in app settings')),
        );
      }
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );

      if (image != null) {
        debugPrint('Image picked: ${image.path}');
        // Save the image path
        await StorageService.saveProfileImage(image.path);
        
        // Reload the profile image
        await _loadProfileImage();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'Profile',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickProfileImage,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              border: Border.all(color: AppTheme.primary, width: 3),
                            ),
                            child: _profileImagePath != null && _profileImagePath!.isNotEmpty
                                ? ClipOval(
                                    child: Image.file(
                                      File(_profileImagePath!),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: AppTheme.primary,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    size: 60,
                                    color: AppTheme.primary,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _userEmail,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Stats Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat(context, '24', 'Recipes Tried'),
                          _buildStat(context, '12', 'Favorites'),
                          _buildStat(context, '5', 'Created'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Profile Options
                  _buildSectionHeader(context, 'Account'),
                  const SizedBox(height: 12),
                  _buildOptionTile(
                    context,
                    icon: Icons.edit,
                    title: 'Edit Profile',
                    onTap: () => _showEditProfileDialog(),
                  ),
                  _buildOptionTile(
                    context,
                    icon: Icons.info,
                    title: 'About Us',
                    onTap: () => _showAboutUsDialog(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Settings Section
                  _buildSectionHeader(context, 'Settings'),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text('Dark Mode', style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : null,
                          )),
                          subtitle: Text('Enable dark theme', style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white70 
                                : null,
                          )),
                          value: context.watch<ThemeProvider>().isDarkMode,
                          onChanged: (value) {
                            context.read<ThemeProvider>().setDarkMode(value);
                          },
                        ),
                        const Divider(),
                        ListTile(
                          title: Text('Preferred Category', style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : null,
                          )),
                          subtitle: Text(context.watch<SettingsProvider>().preferredCategory, style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white70 
                                : null,
                          )),
                          trailing: Icon(Icons.chevron_right, color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : null),
                          onTap: _showCategoryDialog,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : Colors.black,
        )),
        trailing: Icon(Icons.chevron_right, color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white 
            : Colors.black),
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile', style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            )),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _userName = nameController.text.isNotEmpty ? nameController.text : _userName;
                _userEmail = emailController.text.isNotEmpty ? emailController.text : _userEmail;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog() {
    final settingsProvider = context.read<SettingsProvider>();
    final categories = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Snack'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Preferred Category', style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: categories.map((category) {
            return RadioListTile<String>(
              title: Text(category, style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              )),
              value: category,
              groupValue: settingsProvider.preferredCategory,
              onChanged: (value) {
                settingsProvider.updatePreferredCategory(value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  
  void _showPermissionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('App Permissions', style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPermissionItem('Camera', ImageService.isPermissionRequired('camera')),
            _buildPermissionItem('Location', true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            )),
          ),
          TextButton(
            onPressed: () {
              ImageService.openAppSettings();
              Navigator.pop(context);
            },
            child: Text('Open Settings', style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String permission, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            permission,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isRequired ? 'Required' : 'Not required',
            style: TextStyle(
              color: isRequired ? Colors.orange : Colors.green,
              fontSize: 12,
            ),
          ),
          if (isRequired) ...[
            const SizedBox(height: 4),
            Text(
              ImageService.getPermissionExplanation(permission.toLowerCase()),
              style: TextStyle(
                fontSize: 12, 
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Never';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showAboutUsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About TasteTrack'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TasteTrack - Your Personal Recipe Companion',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Developed by:'),
            SizedBox(height: 8),
            Text('1. Student ID: 0225/15 - Bonsa Tujo'),
            Text('2. Student ID: 0920/15 - Selehadin Nesredin'),
            Text('3. Student ID: 1019/15 - Tsion Zekaryas'),
            Text('4. Student ID: 1119/15 - Muaz Abraham'),
            Text('5. Student ID: 0846/15 - Nebiyu Kille'),
            SizedBox(height: 16),
            Text('Version: 1.0.0'),
            Text('© 2024 TasteTrack Team'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
