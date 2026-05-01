import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testetrack/providers/recipe_provider.dart';
import 'package:testetrack/providers/settings_provider.dart';
import 'package:testetrack/providers/theme_provider.dart';
import 'package:testetrack/core/app_theme.dart';
import 'package:testetrack/main_layout.dart';
 
void main() => runApp(TasteTrackApp());
 
class TasteTrackApp extends StatelessWidget {
  const TasteTrackApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'TasteTrack',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const MainLayout(),
          );
        },
      ),
    );
  }
}
