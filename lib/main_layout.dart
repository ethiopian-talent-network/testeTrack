import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import '../screens/add_recipe_screen.dart';
import '../screens/recipe_detail_screen.dart';
import '../screens/location_screen.dart';
import '../widgets/app_navigation.dart';
 
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
 
  @override
  State<MainLayout> createState() => _MainLayoutState();
}
 
class _MainLayoutState extends State<MainLayout> {
  String _currentRoute = '/home';
 
  void _navigate(String route) {
    setState(() {
      _currentRoute = route;
    });
  }
 
  Widget _getCurrentScreen() {
    switch (_currentRoute) {
      case '/home':
        return const DashboardScreen();
      case '/favorites':
        return const FavoritesScreen();
      case '/settings':
        return const ProfileScreen();
      case '/add_recipe':
        return const AddRecipeScreen();
      case '/location':
        return const LocationScreen();
      case '/categories':
        return const DashboardScreen(); // TODO: Create categories screen
      case '/profile':
        return const ProfileScreen();
      default:
        return const DashboardScreen();
    }
  }
 
  // Global navigator key for app-wide navigation
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
 
  static void navigateToRecipeDetail(BuildContext context, dynamic recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: _getCurrentScreen(),
          ),
          // Sticky navigation bar
          AppNavigation(
            currentRoute: _currentRoute,
            onNavigate: _navigate,
          ),
        ],
      ),
    );
  }
}
