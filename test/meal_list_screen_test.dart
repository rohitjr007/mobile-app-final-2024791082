import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recipe_explorer/models/category.dart';
import 'package:recipe_explorer/models/meal.dart';
import 'package:recipe_explorer/screens/home_screen.dart';
import 'package:recipe_explorer/screens/meal_detail_screen.dart';
import 'package:recipe_explorer/screens/meal_list_screen.dart';
import 'package:recipe_explorer/services/api_service.dart';
import 'package:recipe_explorer/widgets/category_card.dart';
import 'package:recipe_explorer/widgets/meal_card.dart';

const _meal = Meal(id: '1', name: 'Grilled Salmon', thumbnailUrl: null);

class _FakeApiService extends ApiService {
  _FakeApiService(this.loadMeals);

  final Future<List<Meal>> Function() loadMeals;
  final requestedCategories = <String>[];
  final requestedMealIds = <String>[];

  @override
  Future<Meal?> fetchMealDetails(String id) async {
    requestedMealIds.add(id);
    return const Meal(
      id: '1',
      name: 'Grilled Salmon',
      thumbnailUrl: null,
      instructions: 'Grill until cooked through.',
    );
  }

  @override
  Future<List<Category>> fetchCategories() async => const [
    Category(
      id: '1',
      name: 'Seafood',
      thumbnailUrl: 'https://example.invalid/seafood.png',
      description: 'Seafood recipes',
    ),
  ];

  @override
  Future<List<Meal>> fetchMealsByCategory(String category) {
    requestedCategories.add(category);
    return loadMeals();
  }
}

void main() {
  testWidgets('opens the selected category, displays meals, and goes back', (
    tester,
  ) async {
    final response = Completer<List<Meal>>();
    final service = _FakeApiService(() => response.future);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(apiService: service)));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(CategoryCard, 'Seafood'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(service.requestedCategories, ['Seafood']);
    expect(find.widgetWithText(AppBar, 'Seafood'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    response.complete([_meal]);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.widgetWithText(MealCard, _meal.name), findsOneWidget);

    await tester.tap(find.text(_meal.name));
    await tester.pumpAndSettle();

    expect(service.requestedMealIds, [_meal.id]);
    expect(find.byType(MealDetailScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Grill until cooked through.'),
      150,
    );
    expect(find.text('Grill until cooked through.'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(MealListScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Recipe Explorer'), findsOneWidget);
    expect(find.byType(MealListScreen), findsNothing);
  });

  testWidgets('shows an error and retries the same category', (tester) async {
    var attempt = 0;
    final service = _FakeApiService(() async {
      if (attempt++ == 0) throw const ApiException('Request failed.');
      return [_meal];
    });
    await tester.pumpWidget(
      MaterialApp(
        home: MealListScreen(categoryName: 'Seafood', apiService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load meals.'), findsOneWidget);
    expect(find.byType(MealCard), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(service.requestedCategories, ['Seafood', 'Seafood']);
    expect(find.text('Could not load meals.'), findsNothing);
    expect(find.widgetWithText(MealCard, _meal.name), findsOneWidget);
  });

  testWidgets('shows an empty state when the category has no meals', (
    tester,
  ) async {
    final service = _FakeApiService(() async => []);
    await tester.pumpWidget(
      MaterialApp(
        home: MealListScreen(categoryName: 'Seafood', apiService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No meals are available in this category.'),
      findsOneWidget,
    );
    expect(find.byType(MealCard), findsNothing);
  });
}
