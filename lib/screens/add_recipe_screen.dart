import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/recipe.dart';
import '../services/image_service.dart';
import '../providers/recipe_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/feedback_dialog.dart';
import '../widgets/loading_widget.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _servingsController = TextEditingController(text: '4');
  final _caloriesController = TextEditingController(text: '350');

  String _selectedCategory = 'Lunch';
  String _selectedComplexity = 'Medium';
  List<String> _ingredients = [''];
  List<String> _instructions = [''];
  String? _imagePath;
  bool _isLoading = false;

  final List<String> _categories = ['Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Snack'];
  final List<String> _complexities = ['Simple', 'Medium', 'Hard'];

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final imagePath = await ImageService.pickImageFromCamera(context: context);

      if (mounted) {
        setState(() {
          _imagePath = imagePath;
          _isLoading = false;
        });

        if (imagePath == null) {
          // User cancelled or permission denied - don't show error for cancellation
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        FeedbackDialog.showError(context, 'Image Error', 'Failed to pick image: $e');
      }
    }
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add('');
    });
  }

  void _removeIngredient(int index) {
    if (_ingredients.length > 1) {
      setState(() {
        _ingredients.removeAt(index);
      });
    }
  }

  void _updateIngredient(int index, String value) {
    setState(() {
      _ingredients[index] = value;
    });
  }

  void _addInstruction() {
    setState(() {
      _instructions.add('');
    });
  }

  void _removeInstruction(int index) {
    if (_instructions.length > 1) {
      setState(() {
        _instructions.removeAt(index);
      });
    }
  }

  void _updateInstruction(int index, String value) {
    setState(() {
      _instructions[index] = value;
    });
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Saving recipe: ${_titleController.text}');
      final recipe = Recipe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        category: _selectedCategory,
        duration: _durationController.text,
        complexity: _selectedComplexity,
        imageUrl: _imagePath ?? 'https://images.unsplash.com/photo-1547592166-3ac5de0382de?w=400',
        ingredients: _ingredients.where((ing) => ing.isNotEmpty).toList(),
        instructions: _instructions.where((inst) => inst.isNotEmpty).toList(),
        servings: int.tryParse(_servingsController.text) ?? 4,
        calories: int.tryParse(_caloriesController.text) ?? 350,
      );

      await context.read<RecipeProvider>().addRecipe(recipe);

      setState(() {
        _isLoading = false;
      });

      // Show success message and stay on the page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe added successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Clear the form for new recipe
      if (mounted) {
        _formKey.currentState?.reset();
        _titleController.clear();
        _durationController.clear();
        _servingsController.text = '4';
        _caloriesController.text = '350';
        setState(() {
          _selectedCategory = 'Lunch';
          _selectedComplexity = 'Medium';
          _ingredients = [''];
          _instructions = [''];
          _imagePath = null;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      FeedbackDialog.showError(context, 'Error', 'Failed to save recipe: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'Add Recipe',
            showBackButton: true,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImageSection(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Basic Information'),
                          const SizedBox(height: 16),
                          _buildBasicInfoSection(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Category & Complexity'),
                          const SizedBox(height: 16),
                          _buildCategorySection(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Ingredients'),
                          const SizedBox(height: 16),
                          _buildIngredientsSection(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Instructions'),
                          const SizedBox(height: 16),
                          _buildInstructionsSection(),
                          const SizedBox(height: 32),
                          LoadingButton(
                            text: 'Save Recipe',
                            onPressed: _saveRecipe,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
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

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recipe Image',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3) ??
                        Colors.grey.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).cardColor,
                ),
                child: _imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 48,
                            color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5) ??
                                Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add image',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Recipe Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a recipe title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (e.g., 30 min)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter duration';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    decoration: const InputDecoration(
                      labelText: 'Servings',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter servings';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories per serving',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter calories';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedComplexity,
              decoration: const InputDecoration(
                labelText: 'Complexity',
                border: OutlineInputBorder(),
              ),
              items: _complexities.map((complexity) {
                return DropdownMenuItem(
                  value: complexity,
                  child: Text(complexity),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedComplexity = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Ingredient'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._ingredients.asMap().entries.map((entry) {
              final index = entry.key;
              final ingredient = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: ingredient,
                        decoration: InputDecoration(
                          labelText: 'Ingredient ${index + 1}',
                          border: const OutlineInputBorder(),
                          suffixIcon: _ingredients.length > 1
                              ? IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _removeIngredient(index),
                                )
                              : null,
                        ),
                        onChanged: (value) => _updateIngredient(index, value),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter ingredient';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Instructions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addInstruction,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Step'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._instructions.asMap().entries.map((entry) {
              final index = entry.key;
              final instruction = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: instruction,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Step ${index + 1}',
                          border: const OutlineInputBorder(),
                          suffixIcon: _instructions.length > 1
                              ? IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _removeInstruction(index),
                                )
                              : null,
                        ),
                        onChanged: (value) => _updateInstruction(index, value),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter instruction';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
