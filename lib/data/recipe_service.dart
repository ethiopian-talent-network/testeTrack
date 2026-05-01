import 'package:testetrack/models/recipe.dart';
import 'package:testetrack/services/storage_services.dart';
import 'package:testetrack/services/api_services.dart';


class RecipeService {
  static List<Recipe> _recipes = [];
  static final List<Recipe> _localRecipes = []; // User-created recipes
  static List<Recipe>? _cachedFavorites;
  static bool _isLoading = false;
  static String? _error;


  static Future<List<Recipe>> getAllRecipes({bool forceRefresh = false}) async {
    if (_recipes.isEmpty || forceRefresh) {
      try {
        _isLoading = true;
        _error = null;

        // Try to fetch from API first
        final apiRecipes = await ApiService.fetchRecipes();

        // Combine with local recipes
        final localRecipes = _getLocalRecipes();
        _recipes = [...apiRecipes, ...localRecipes];

        _isLoading = false;
      } catch (e) {
        _error = e.toString();
        _isLoading = false;

        // Fallback to local recipes if API fails
        _recipes = _getLocalRecipes();
      }
    }
    return _recipes;
  }


  static Future<List<Recipe>> getFavoriteRecipes() async {
    if (_cachedFavorites == null) {
      final favoriteIds = await StorageService.getFavoriteRecipeIds();
      final allRecipes = await getAllRecipes();

      _cachedFavorites = allRecipes
          .where((recipe) => favoriteIds.contains(recipe.id))
          .toList();
    }
    return _cachedFavorites!;
  }


  static Future<void> toggleFavorite(Recipe recipe) async {
    final isFav = await isFavorite(recipe);

    if (isFav) {
      await StorageService.removeFavorite(recipe.id);
    } else {
      await StorageService.addFavorite(recipe.id);
    }

    // Clear cache to refresh
    _cachedFavorites = null;
  }


  static Future<bool> isFavorite(Recipe recipe) async {
    return await StorageService.isFavorite(recipe.id);
  }


  static Future<List<Recipe>> searchRecipes(String query, String category) async {
    try {
      _isLoading = true;
      _error = null;

      List<Recipe> results = [];

      if (query.isNotEmpty) {
        // Get all recipes for comprehensive search
        final allRecipes = await getAllRecipes();

        // Enhanced search with better matching
        final matchingRecipes = allRecipes.where((recipe) {
          final matchesCategory = category == 'All' || recipe.category == category;
          if (!matchesCategory) return false;

          final queryLower = query.toLowerCase();

          // Title matching (highest priority)
          if (recipe.title.toLowerCase().contains(queryLower)) {
            return true;
          }

          // Ingredient matching (high priority)
          if (recipe.ingredients.any((ing) => ing.toLowerCase().contains(queryLower))) {
            return true;
          }

          // Category matching (medium priority)
          if (recipe.category.toLowerCase().contains(queryLower)) {
            return true;
          }

          // Partial word matching in title
          final titleWords = recipe.title.toLowerCase().split(' ');
          if (titleWords.any((word) => word.startsWith(queryLower) || queryLower.startsWith(word))) {
            return true;
          }

          // Partial word matching in ingredients
          for (final ingredient in recipe.ingredients) {
            final ingredientWords = ingredient.toLowerCase().split(' ');
            if (ingredientWords.any((word) => word.startsWith(queryLower) || queryLower.startsWith(word))) {
              return true;
            }
          }

          return false;
        }).toList();

        // Sort results by relevance
        matchingRecipes.sort((a, b) {
          final queryLower = query.toLowerCase();
          final aTitle = a.title.toLowerCase();
          final bTitle = b.title.toLowerCase();

          // Exact title match gets highest priority
          final aExactTitle = aTitle == queryLower;
          final bExactTitle = bTitle == queryLower;
          if (aExactTitle && !bExactTitle) return -1;
          if (!aExactTitle && bExactTitle) return 1;

          // Title starts with query gets high priority
          final aTitleStarts = aTitle.startsWith(queryLower);
          final bTitleStarts = bTitle.startsWith(queryLower);
          if (aTitleStarts && !bTitleStarts) return -1;
          if (!aTitleStarts && bTitleStarts) return 1;

          // Query contains in title gets medium priority
          final aTitleContains = aTitle.contains(queryLower);
          final bTitleContains = bTitle.contains(queryLower);
          if (aTitleContains && !bTitleContains) return -1;
          if (!aTitleContains && bTitleContains) return 1;

          return 0;
        });

        results = matchingRecipes;
      } else {
        results = await getAllRecipes();
      }

      _isLoading = false;
      return results;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;

      // Fallback to local search
      final allRecipes = await getAllRecipes();
      return allRecipes.where((recipe) {
        final matchesCategory = category == 'All' || recipe.category == category;
        if (!matchesCategory) return false;

        if (query.isEmpty) return true;

        final queryLower = query.toLowerCase();
        return recipe.title.toLowerCase().contains(queryLower) ||
            recipe.ingredients.any((ing) => ing.toLowerCase().contains(queryLower)) ||
            recipe.category.toLowerCase().contains(queryLower);
      }).toList();
    }
  }


  static List<String> getCategories() {
    return ['All', 'Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Snack'];
  }


  static bool get isLoading => _isLoading;
  static String? get error => _error;


  static void clearCache() {
    _recipes.clear();
    _cachedFavorites = null;
    _error = null;
  }


  static List<Recipe> _getLocalRecipes() {
    if (_recipes.isEmpty) {
      _initializeRecipes();
    }
    // Include both default recipes (id starts with 'r') and user-created recipes
    final defaultRecipes = _recipes.where((recipe) => recipe.id.startsWith('r')).toList();
    return [...defaultRecipes, ..._localRecipes];
  }


  static void _initializeRecipes() {
    _recipes = [
      Recipe(
        id: 'r1',
        title: 'Classic Spaghetti Carbonara',
        imageUrl: 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6',
        duration: '25 min',
        complexity: 'Medium',
        category: 'Dinner',
        ingredients: [
          '400g Spaghetti',
          '200g Pancetta or Guanciale',
          '4 Large Eggs',
          '100g Pecorino Romano Cheese',
          'Black Pepper',
          'Salt'
        ],
        instructions: [
          'Bring a large pot of salted water to boil',
          'Cook spaghetti according to package directions',
          'Meanwhile, dice pancetta and cook until crispy',
          'Beat eggs with grated cheese and black pepper',
          'Drain pasta, reserving 1 cup pasta water',
          'Mix hot pasta with pancetta, then egg mixture',
          'Add pasta water to achieve creamy consistency',
          'Serve immediately with extra cheese'
        ],
        servings: 4,
        calories: 420,
      ),
      Recipe(
        id: 'r2',
        title: 'Gourmet Veggie Burger',
        imageUrl: 'https://images.unsplash.com/photo-1550547660-d9450f859349',
        duration: '35 min',
        complexity: 'Medium',
        category: 'Lunch',
        ingredients: [
          '4 Burger Buns',
          '2 Black Bean Patties',
          'Lettuce Leaves',
          'Ripe Tomato',
          'Red Onion',
          'Avocado',
          'Cheddar Cheese',
          'Pickles',
          'Special Sauce'
        ],
        instructions: [
          'Toast burger buns until golden brown',
          'Cook veggie patties according to package instructions',
          'Add cheese to patties while hot',
          'Wash and slice vegetables',
          'Mash avocado with salt and pepper',
          'Assemble burger with sauce, patty, and vegetables',
          'Serve with fries or salad'
        ],
        servings: 4,
        calories: 520,
      ),
      Recipe(
        id: 'r3',
        title: 'Avocado Toast Deluxe',
        imageUrl: 'https://images.unsplash.com/photo-1588137378631-dea1336ce1e2',
        duration: '15 min',
        complexity: 'Simple',
        category: 'Breakfast',
        ingredients: [
          '4 Slices Sourdough Bread',
          '2 Ripe Avocados',
          'Lemon Juice',
          'Red Pepper Flakes',
          'Hemp Seeds',
          'Cherry Tomatoes',
          'Microgreens',
          'Salt',
          'Poached Eggs (optional)'
        ],
        instructions: [
          'Toast bread until golden and crispy',
          'Mash avocados with lemon juice, salt, and pepper',
          'Spread avocado mixture on toast',
          'Top with sliced cherry tomatoes',
          'Sprinkle with red pepper flakes and hemp seeds',
          'Add microgreens for freshness',
          'Top with poached egg if desired'
        ],
        servings: 2,
        calories: 380,
      ),
      Recipe(
        id: 'r4',
        title: 'Decadent Chocolate Lava Cake',
        imageUrl: 'https://images.unsplash.com/photo-1578982961441-38d9a3ea3377',
        duration: '20 min',
        complexity: 'Hard',
        category: 'Dessert',
        ingredients: [
          '200g Dark Chocolate',
          '200g Butter',
          '4 Eggs',
          '100g Sugar',
          '100g Flour',
          'Vanilla Extract',
          'Powdered Sugar',
          'Vanilla Ice Cream'
        ],
        instructions: [
          'Preheat oven to 200°C (392°F)',
          'Melt chocolate and butter together',
          'Whisk eggs and sugar until pale',
          'Fold chocolate mixture into eggs',
          'Add flour and vanilla extract',
          'Pour into greased ramekins',
          'Bake for 12-14 minutes until edges are firm',
          'Serve immediately with ice cream'
        ],
        servings: 4,
        calories: 580,
      ),
      Recipe(
        id: 'r5',
        title: 'Mediterranean Quinoa Bowl',
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
        duration: '25 min',
        complexity: 'Simple',
        category: 'Lunch',
        ingredients: [
          '1 cup Quinoa',
          'Cucumber',
          'Cherry Tomatoes',
          'Red Onion',
          'Kalamata Olives',
          'Feta Cheese',
          'Chickpeas',
          'Lemon',
          'Olive Oil',
          'Fresh Herbs'
        ],
        instructions: [
          'Cook quinoa according to package directions',
          'Dice cucumber and halve cherry tomatoes',
          'Slice red onion thinly',
          'Combine quinoa with vegetables and chickpeas',
          'Add crumbled feta cheese and olives',
          'Make dressing with lemon juice, olive oil, and herbs',
          'Drizzle dressing over bowl',
          'Serve warm or cold'
        ],
        servings: 4,
        calories: 320,
      ),
      Recipe(
        id: 'r6',
        title: 'Green Power Smoothie',
        imageUrl: 'https://images.unsplash.com/photo-1505252585461-04db1eb84625',
        duration: '5 min',
        complexity: 'Simple',
        category: 'Snack',
        ingredients: [
          '1 Banana',
          '1 cup Spinach',
          '1 cup Mixed Berries',
          '1 cup Almond Milk',
          '1 tbsp Chia Seeds',
          '1 tbsp Honey',
          'Ice Cubes',
          'Protein Powder (optional)'
        ],
        instructions: [
          'Add all ingredients to blender',
          'Blend until smooth and creamy',
          'Add more ice if desired consistency',
          'Taste and adjust sweetness',
          'Pour into glass',
          'Garnish with berries and seeds',
          'Serve immediately'
        ],
        servings: 2,
        calories: 180,
      ),
      Recipe(
        id: 'r7',
        title: 'Asian Stir-Fry Noodles',
        imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38',
        duration: '30 min',
        complexity: 'Medium',
        category: 'Dinner',
        ingredients: [
          '300g Rice Noodles',
          'Mixed Vegetables',
          'Tofu or Chicken',
          'Soy Sauce',
          'Ginger',
          'Garlic',
          'Sesame Oil',
          'Green Onions',
          'Sesame Seeds'
        ],
        instructions: [
          'Cook noodles according to package',
          'Heat oil in wok or large pan',
          'Add protein and cook until done',
          'Add vegetables and stir-fry',
          'Add garlic and ginger',
          'Add cooked noodles and sauce',
          'Toss everything together',
          'Garnish with green onions and sesame seeds'
        ],
        servings: 4,
        calories: 380,
      ),
      Recipe(
        id: 'r8',
        title: 'Overnight Oats Paradise',
        imageUrl: 'https://images.unsplash.com/photo-1525373612132-b3e820b87cea',
        duration: '5 min + overnight',
        complexity: 'Simple',
        category: 'Breakfast',
        ingredients: [
          '1 cup Rolled Oats',
          '1 cup Milk or Yogurt',
          'Chia Seeds',
          'Maple Syrup',
          'Vanilla Extract',
          'Fresh Berries',
          'Nuts',
          'Cinnamon'
        ],
        instructions: [
          'Mix oats, milk, and chia seeds',
          'Add maple syrup and vanilla',
          'Divide into jars or containers',
          'Refrigerate overnight',
          'Top with fresh berries and nuts',
          'Sprinkle with cinnamon',
          'Enjoy cold or warmed up'
        ],
        servings: 2,
        calories: 280,
      ),
      Recipe(
        id: 'r9',
        title: 'Homemade Pizza Margherita',
        imageUrl: 'https://images.unsplash.com/photo-1593560708920-61dd98c46a4e',
        duration: '45 min',
        complexity: 'Hard',
        category: 'Dinner',
        ingredients: [
          'Pizza Dough',
          'Tomato Sauce',
          'Fresh Mozzarella',
          'Fresh Basil',
          'Olive Oil',
          'Salt',
          'Oregano',
          'Garlic'
        ],
        instructions: [
          'Preheat oven to highest temperature',
          'Roll out pizza dough',
          'Spread tomato sauce evenly',
          'Add torn mozzarella pieces',
          'Drizzle with olive oil',
          'Bake for 10-12 minutes',
          'Top with fresh basil',
          'Slice and serve hot'
        ],
        servings: 4,
        calories: 450,
      ),
      Recipe(
        id: 'r10',
        title: 'Energy Protein Balls',
        imageUrl: 'https://images.unsplash.com/photo-1505253716362-afaea1d3d1af',
        duration: '15 min',
        complexity: 'Simple',
        category: 'Snack',
        ingredients: [
          '1 cup Dates',
          '1 cup Nuts',
          'Protein Powder',
          'Cocoa Powder',
          'Coconut Flakes',
          'Chia Seeds',
          'Vanilla Extract',
          'Salt'
        ],
        instructions: [
          'Pit dates and soak if needed',
          'Toast nuts lightly',
          'Blend dates and nuts in food processor',
          'Add protein powder and cocoa',
          'Mix in vanilla and salt',
          'Roll into small balls',
          'Roll in coconut flakes',
          'Refrigerate for 30 minutes'
        ],
        servings: 12,
        calories: 120,
      ),
      // Ethiopian Recipes
      Recipe(
        id: 'r11',
        title: 'Injera with Doro Wat',
        imageUrl: 'https://images.unsplash.com/photo-1584982777203-6b5f22d8ad73',
        duration: '2 hours',
        complexity: 'Hard',
        category: 'Dinner',
        ingredients: [
          '2 cups Teff flour',
          '3 cups Water',
          '1 whole Chicken',
          '2 large Onions',
          '4 cloves Garlic',
          '1 inch Ginger',
          '2 tbsp Berbere spice',
          '1 tsp Turmeric',
          '1/4 cup Niter Kibbeh (spiced butter)',
          '6 Hard-boiled Eggs',
          'Salt and Pepper'
        ],
        instructions: [
          'Make injera batter 3 days ahead with teff flour and water',
          'Cook injera on special griddle until bubbly',
          'Cut chicken into pieces and clean',
          'Sauté onions until golden brown',
          'Add berbere spice and cook for 2 minutes',
          'Add chicken pieces and brown them',
          'Add garlic, ginger, and water to make sauce',
          'Simmer for 45 minutes until chicken is tender',
          'Add hard-boiled eggs and simmer 10 more minutes',
          'Serve with injera on the side'
        ],
        servings: 6,
        calories: 380,
      ),
      Recipe(
        id: 'r12',
        title: 'Kitfo (Ethiopian Raw Beef)',
        imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38',
        duration: '30 min',
        complexity: 'Medium',
        category: 'Dinner',
        ingredients: [
          '1 lb Lean beef tenderloin',
          '2 tbsp Niter Kibbeh (spiced butter)',
          '1 tbsp Mitmita spice blend',
          '1 tsp Cardamom',
          'Collard greens (Gomen)',
          'Injera bread',
          'Ayib (Ethiopian cheese)',
          'Salt to taste'
        ],
        instructions: [
          'Trim beef of all fat and connective tissue',
          'Freeze beef for 30 minutes to firm up',
          'Chop beef into very small pieces with sharp knife',
          'Mix with spiced butter and mitmita spices',
          'Add ground cardamom and salt',
          'Serve immediately with injera',
          'Accompany with cooked collard greens',
          'Add ayib cheese on the side'
        ],
        servings: 4,
        calories: 320,
      ),
      Recipe(
        id: 'r13',
        title: 'Shiro Wat (Ethiopian Chickpea Stew)',
        imageUrl: 'https://images.unsplash.com/photo-1546548970-71785318a17b',
        duration: '45 min',
        complexity: 'Easy',
        category: 'Lunch',
        ingredients: [
          '2 cups Chickpea flour',
          '4 cups Water',
          '1 large Onion',
          '3 cloves Garlic',
          '2 tbsp Berbere spice',
          '1 tbsp Turmeric',
          '1/4 cup Olive oil',
          '1 tsp Salt',
          'Injera bread',
          'Lemon wedges'
        ],
        instructions: [
          'Sauté chopped onions until soft and golden',
          'Add minced garlic and cook for 1 minute',
          'Add berbere and turmeric, stir for 30 seconds',
          'Gradually add chickpea flour while whisking',
          'Slowly add water to prevent lumps',
          'Simmer for 30 minutes, stirring frequently',
          'Season with salt and adjust consistency',
          'Serve hot with injera',
          'Garnish with lemon wedges'
        ],
        servings: 6,
        calories: 280,
      ),
      Recipe(
        id: 'r14',
        title: 'Tibbs (Ethiopian Grilled Meat)',
        imageUrl: 'https://images.unsplash.com/photo-1598020996727-1a0463d8607c',
        duration: '1 hour',
        complexity: 'Medium',
        category: 'Dinner',
        ingredients: [
          '2 lbs Beef sirloin',
          '2 large Onions',
          '4 cloves Garlic',
          '2 tbsp Rosemary',
          '1 tbsp Black pepper',
          '1 tsp Cumin',
          '1/2 cup Olive oil',
          '1/4 cup Wine',
          'Injera bread',
          'Salt to taste'
        ],
        instructions: [
          'Cut beef into 1-inch cubes',
          'Marinate beef with garlic, rosemary, and spices',
          'Let marinate for at least 30 minutes',
          'Heat grill or large pan to high heat',
          'Sauté sliced onions until caramelized',
          'Grill beef until charred outside, tender inside',
          'Deglaze pan with wine',
          'Combine beef with onions',
          'Serve with injera'
        ],
        servings: 8,
        calories: 420,
      ),
      Recipe(
        id: 'r15',
        title: 'Gomen (Ethiopian Collard Greens)',
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
        duration: '40 min',
        complexity: 'Easy',
        category: 'Lunch',
        ingredients: [
          '2 lbs Collard greens',
          '1 large Onion',
          '3 cloves Garlic',
          '1 inch Ginger',
          '2 tbsp Niter Kibbeh',
          '1 tsp Turmeric',
          '1/2 tsp Cardamom',
          'Salt and Pepper',
          'Injera bread'
        ],
        instructions: [
          'Wash and chop collard greens',
          'Sauté onions until soft',
          'Add minced garlic and ginger',
          'Add spiced butter and spices',
          'Add collard greens with some water',
          'Simmer for 30 minutes until tender',
          'Season with salt and pepper',
          'Serve with injera'
        ],
        servings: 4,
        calories: 180,
      ),
      Recipe(
        id: 'r16',
        title: 'Sambusa (Ethiopian Samosa)',
        imageUrl: 'https://images.unsplash.com/photo-1565958011703-47f4969c6f24',
        duration: '1 hour',
        complexity: 'Medium',
        category: 'Snack',
        ingredients: [
          '20 Spring roll wrappers',
          '1 lb Ground beef',
          '1 large Onion',
          '2 cloves Garlic',
          '1 tsp Cumin',
          '1 tsp Cardamom',
          '1 tsp Paprika',
          '1/4 cup Chopped cilantro',
          'Oil for frying',
          'Salt to taste'
        ],
        instructions: [
          'Cook ground beef with onions and garlic',
          'Add spices and cook until fragrant',
          'Add cilantro and let cool',
          'Cut spring roll wrappers into triangles',
          'Place filling on each wrapper',
          'Fold into triangle shape',
          'Deep fry until golden brown',
          'Serve hot with dipping sauce'
        ],
        servings: 20,
        calories: 85,
      ),
      // Additional Recipes
      Recipe(
        id: 'r17',
        title: 'Mediterranean Quinoa Bowl',
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
        duration: '25 min',
        complexity: 'Easy',
        category: 'Lunch',
        ingredients: [
          '1 cup Quinoa',
          '2 cups Vegetable broth',
          '1 cup Cherry tomatoes',
          '1 cup Cucumber',
          '1/2 cup Red onion',
          '1/2 cup Kalamata olives',
          '1/4 cup Feta cheese',
          '2 tbsp Olive oil',
          '1 tbsp Lemon juice',
          'Fresh herbs (parsley, mint)',
          'Salt and pepper'
        ],
        instructions: [
          'Cook quinoa in vegetable broth until fluffy',
          'Let quinoa cool to room temperature',
          'Dice tomatoes, cucumber, and red onion',
          'Mix vegetables with quinoa',
          'Add olives and crumbled feta',
          'Drizzle with olive oil and lemon juice',
          'Toss with fresh herbs',
          'Season with salt and pepper',
          'Serve chilled or at room temperature'
        ],
        servings: 4,
        calories: 320,
      ),
      Recipe(
        id: 'r18',
        title: 'Thai Green Curry',
        imageUrl: 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445',
        duration: '35 min',
        complexity: 'Medium',
        category: 'Dinner',
        ingredients: [
          '2 tbsp Green curry paste',
          '400ml Coconut milk',
          '500g Chicken breast',
          '1 cup Thai basil',
          '2 Eggplants',
          '100g Green beans',
          '3 Thai chilies',
          '2 tbsp Fish sauce',
          '1 tbsp Palm sugar',
          '2 kaffir lime leaves',
          'Jasmine rice'
        ],
        instructions: [
          'Heat curry paste in pan until fragrant',
          'Add coconut milk and bring to simmer',
          'Add chicken pieces and cook through',
          'Add eggplant and green beans',
          'Season with fish sauce and palm sugar',
          'Add lime leaves and Thai basil',
          'Simmer until vegetables are tender',
          'Serve over jasmine rice'
        ],
        servings: 6,
        calories: 380,
      ),
      Recipe(
        id: 'r19',
        title: 'Mexican Street Tacos',
        imageUrl: 'https://images.unsplash.com/photo-1551504734-5ee1c4a179cd',
        duration: '30 min',
        complexity: 'Medium',
        category: 'Dinner',
        ingredients: [
          '1 lb Beef sirloin',
          '12 Corn tortillas',
          '1 white onion',
          '1 bunch Cilantro',
          '2 limes',
          '2 jalapeños',
          '1 tsp Cumin',
          '1 tsp Paprika',
          'Salt and pepper',
          'Salsa verde',
          'Radishes'
        ],
        instructions: [
          'Season beef with cumin, paprika, salt, pepper',
          'Grill beef to medium-rare, let rest',
          'Slice beef thinly against the grain',
          'Warm tortillas on griddle',
          'Dice onion and cilantro',
          'Slice jalapeños and radishes',
          'Assemble tacos with beef, onion, cilantro',
          'Serve with lime wedges and salsa'
        ],
        servings: 6,
        calories: 280,
      ),
      Recipe(
        id: 'r20',
        title: 'Japanese Ramen Bowl',
        imageUrl: 'https://images.unsplash.com/photo-1569716212802-39d3c4d56c97',
        duration: '4 hours',
        complexity: 'Hard',
        category: 'Dinner',
        ingredients: [
          '2 lbs Pork bones',
          '1 lb Pork belly',
          '4 packs Ramen noodles',
          '6 eggs',
          '4 cups Green onions',
          '2 cups Bean sprouts',
          '1 cup Nori sheets',
          '1/4 cup Soy sauce',
          '2 tbsp Miso paste',
          '1 tbsp Sesame oil',
          'Garlic and ginger'
        ],
        instructions: [
          'Simmer pork bones for 3 hours to make broth',
          'Marinate and slow-cook pork belly',
          'Prepare soft-boiled eggs',
          'Cook ramen noodles separately',
          'Season broth with soy sauce and miso',
          'Slice pork belly and eggs in half',
          'Assemble bowls with noodles, broth, pork',
          'Top with eggs, green onions, sprouts, nori'
        ],
        servings: 6,
        calories: 450,
      ),
      Recipe(
        id: 'r21',
        title: 'Indian Butter Chicken',
        imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38',
        duration: '45 min',
        complexity: 'Medium',
        category: 'Dinner',
        ingredients: [
          '2 lbs Chicken thighs',
          '1 cup Yogurt',
          '2 tbsp Garam masala',
          '1 tbsp Turmeric',
          '1 tbsp Paprika',
          '2 cups Tomato puree',
          '1 cup Heavy cream',
          '4 tbsp Butter',
          '3 cloves Garlic',
          '1 inch Ginger',
          'Basmati rice',
          'Naan bread'
        ],
        instructions: [
          'Marinate chicken in yogurt and spices',
          'Grill or pan-fry chicken until charred',
          'Sauté garlic and ginger in butter',
          'Add tomato puree and simmer',
          'Add cream and grilled chicken',
          'Season with garam masala',
          'Simmer for 20 minutes',
          'Serve with basmati rice and naan'
        ],
        servings: 6,
        calories: 420,
      ),
      Recipe(
        id: 'r22',
        title: 'Greek Moussaka',
        imageUrl: 'https://images.unsplash.com/photo-1598515214211-89d3c23185e4',
        duration: '2 hours',
        complexity: 'Hard',
        category: 'Dinner',
        ingredients: [
          '2 lbs Eggplant',
          '1 lb Ground lamb',
          '1 large Onion',
          '2 cans Crushed tomatoes',
          '1 cup Red wine',
          '1 tsp Cinnamon',
          '1/2 tsp Nutmeg',
          '4 cups Béchamel sauce',
          '1 cup Parmesan',
          'Olive oil',
          'Fresh parsley'
        ],
        instructions: [
          'Slice and salt eggplant, let drain',
          'Fry eggplant slices until golden',
          'Cook lamb with onions and spices',
          'Add tomatoes and wine, simmer',
          'Layer eggplant and meat sauce',
          'Top with béchamel and cheese',
          'Bake at 350°F for 45 minutes',
          'Let rest 15 minutes before serving'
        ],
        servings: 8,
        calories: 380,
      ),
    ];
  }


  // Save a user-created recipe to local storage
  static Future<void> saveLocalRecipe(Recipe recipe) async {
    try {
      // For now, we'll just add it to the in-memory list
      // In a real app, you'd save this to SharedPreferences or a local database
      _localRecipes.add(recipe);
    } catch (e) {
      throw Exception('Failed to save local recipe: $e');
    }
  }
}




