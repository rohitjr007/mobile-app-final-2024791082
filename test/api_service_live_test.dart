import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_explorer/services/api_service.dart';

void main() {
  const service = ApiService();

  test('fetches all recipe categories', () async {
    final categories = await service.fetchCategories();
    debugPrint('Recipe categories: ${categories.length}');
    expect(categories, isNotEmpty);
    expect(categories.map((category) => category.name), contains('Seafood'));
  });

  test('fetches meals in the Seafood category', () async {
    final meals = await service.fetchMealsByCategory('Seafood');
    debugPrint('Seafood meals: ${meals.length}');
    expect(meals, isNotEmpty);
  });

  test('fetches details for a known meal ID', () async {
    const mealId = '52772';
    final meal = await service.fetchMealDetails(mealId);
    debugPrint('Meal details for $mealId: ${meal == null ? 0 : 1}');
    expect(meal?.id, mealId);
    expect(meal?.instructions, isNotEmpty);
  });

  test('searches for meals named chicken', () async {
    final meals = await service.fetchMealsByName('chicken');
    debugPrint('Meals matching "chicken": ${meals.length}');
    expect(meals, isNotEmpty);
    expect(
      meals.map((meal) => meal.name.toLowerCase()),
      contains(contains('chicken')),
    );
  });
}
