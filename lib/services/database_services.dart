import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:testetrack/models/recipe.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'tastetrack.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String recipesTable = 'recipes';
  static const String userRecipesTable = 'user_recipes';

  // Initialize database
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Create recipes table
    await db.execute('''
      CREATE TABLE $recipesTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        image_url TEXT NOT NULL,
        duration TEXT NOT NULL,
        complexity TEXT NOT NULL,
        category TEXT NOT NULL,
        ingredients TEXT NOT NULL, -- JSON array
        instructions TEXT NOT NULL, -- JSON array
        servings INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        is_favorite INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create user recipes table (for user-created recipes)
    await db.execute('''
      CREATE TABLE $userRecipesTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        image_url TEXT NOT NULL,
        duration TEXT NOT NULL,
        complexity TEXT NOT NULL,
        category TEXT NOT NULL,
        ingredients TEXT NOT NULL, -- JSON array
        instructions TEXT NOT NULL, -- JSON array
        servings INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_recipes_category ON $recipesTable(category)');
    await db.execute('CREATE INDEX idx_recipes_favorite ON $recipesTable(is_favorite)');
    await db.execute('CREATE INDEX idx_recipes_created_at ON $recipesTable(created_at)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  // Recipe operations
  static Future<void> insertRecipe(Recipe recipe, {bool isUserRecipe = false}) async {
    final db = await database;
    final tableName = isUserRecipe ? userRecipesTable : recipesTable;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      tableName,
      {
        'id': recipe.id,
        'title': recipe.title,
        'image_url': recipe.imageUrl,
        'duration': recipe.duration,
        'complexity': recipe.complexity,
        'category': recipe.category,
        'ingredients': recipe.ingredients.join('|||'), // Custom delimiter
        'instructions': recipe.instructions.join('|||'), // Custom delimiter
        'servings': recipe.servings,
        'calories': recipe.calories,
        'is_favorite': 0, // Default to not favorite
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Recipe>> getAllRecipes({bool favoritesOnly = false}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      recipesTable,
      where: favoritesOnly ? 'is_favorite = ?' : null,
      whereArgs: favoritesOnly ? [1] : null,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return _mapToRecipe(maps[i]);
    });
  }

  static Future<List<Recipe>> getUserRecipes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      userRecipesTable,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return _mapToRecipe(maps[i]);
    });
  }

  static Future<List<Recipe>> searchRecipes(String query, String category) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    // Build where clause
    if (query.isNotEmpty && category != 'All') {
      whereClause = 'title LIKE ? AND category = ?';
      whereArgs = ['%$query%', category];
    } else if (query.isNotEmpty) {
      whereClause = 'title LIKE ?';
      whereArgs = ['%$query%'];
    } else if (category != 'All') {
      whereClause = 'category = ?';
      whereArgs = [category];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      recipesTable,
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return _mapToRecipe(maps[i]);
    });
  }

  static Future<void> toggleFavorite(String recipeId) async {
    final db = await database;
    
    // Get current favorite status
    final List<Map<String, dynamic>> maps = await db.query(
      recipesTable,
      columns: ['is_favorite'],
      where: 'id = ?',
      whereArgs: [recipeId],
    );

    if (maps.isNotEmpty) {
      final currentFavorite = maps.first['is_favorite'] == 1;
      await db.update(
        recipesTable,
        {
          'is_favorite': currentFavorite ? 0 : 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [recipeId],
      );
    }
  }

  static Future<bool> isFavorite(String recipeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      recipesTable,
      columns: ['is_favorite'],
      where: 'id = ?',
      whereArgs: [recipeId],
    );

    return maps.isNotEmpty && maps.first['is_favorite'] == 1;
  }

  static Future<void> deleteRecipe(String recipeId, {bool isUserRecipe = false}) async {
    final db = await database;
    final tableName = isUserRecipe ? userRecipesTable : recipesTable;
    
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [recipeId],
    );
  }

  static Future<void> updateRecipe(Recipe recipe, {bool isUserRecipe = false}) async {
    final db = await database;
    final tableName = isUserRecipe ? userRecipesTable : recipesTable;
    
    await db.update(
      tableName,
      {
        'title': recipe.title,
        'image_url': recipe.imageUrl,
        'duration': recipe.duration,
        'complexity': recipe.complexity,
        'category': recipe.category,
        'ingredients': recipe.ingredients.join('|||'),
        'instructions': recipe.instructions.join('|||'),
        'servings': recipe.servings,
        'calories': recipe.calories,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  // Helper method to map database row to Recipe object
  static Recipe _mapToRecipe(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      title: map['title'],
      imageUrl: map['image_url'],
      duration: map['duration'],
      complexity: map['complexity'],
      category: map['category'],
      ingredients: (map['ingredients'] as String).split('|||'),
      instructions: (map['instructions'] as String).split('|||'),
      servings: map['servings'],
      calories: map['calories'],
    );
  }

  // Database statistics
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    
    final totalRecipes = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $recipesTable')
    ) ?? 0;
    
    final favoriteRecipes = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $recipesTable WHERE is_favorite = 1')
    ) ?? 0;
    
    final userRecipes = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $userRecipesTable')
    ) ?? 0;

    return {
      'total_recipes': totalRecipes,
      'favorite_recipes': favoriteRecipes,
      'user_recipes': userRecipes,
      'categories': await _getCategoryCount(db),
    };
  }

  static Future<List<String>> _getCategoryCount(Database db) async {
    final result = await db.rawQuery('SELECT DISTINCT category FROM $recipesTable');
    return result.map((row) => row['category'] as String).toList();
  }

  // Close database
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
