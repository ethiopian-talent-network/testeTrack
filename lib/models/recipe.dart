class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final List<String> ingredients;
  final String duration;
  final String complexity;
  final String category;
  final List<String> instructions;
  final int servings;
  final int calories;


  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.ingredients,
    required this.duration,
    required this.complexity,
    this.category = 'Lunch',
    this.instructions = const [],
    this.servings = 4,
    this.calories = 350,
  });
}


