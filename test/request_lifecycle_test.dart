import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recipe_explorer/models/category.dart';
import 'package:recipe_explorer/models/meal.dart';
import 'package:recipe_explorer/screens/home_screen.dart';
import 'package:recipe_explorer/screens/meal_detail_screen.dart';
import 'package:recipe_explorer/screens/meal_list_screen.dart';
import 'package:recipe_explorer/screens/search_screen.dart';
import 'package:recipe_explorer/services/api_service.dart';

class _FailingApiService extends ApiService {
  int attempts = 0;
  final lastRequest = Completer<void>();

  Future<T> respond<T>(T result) async {
    attempts++;
    if (attempts <= 2) throw const ApiException('Network failure');
    if (attempts == 4) await lastRequest.future;
    return result;
  }

  @override
  Future<List<Category>> fetchCategories() => respond([]);

  @override
  Future<List<Meal>> fetchMealsByCategory(String category) => respond([]);

  @override
  Future<Meal?> fetchMealDetails(String id) => respond(null);

  @override
  Future<List<Meal>> fetchMealsByName(String name) => respond([]);
}

void main() {
  final cases = [
    (
      label: 'categories',
      open: (ApiService service) => HomeScreen(apiService: service),
      error: 'Could not load recipe categories.',
      empty: 'No recipe categories are available.',
    ),
    (
      label: 'category meals',
      open: (ApiService service) =>
          MealListScreen(apiService: service, categoryName: 'Seafood'),
      error: 'Could not load meals.',
      empty: 'No meals are available in this category.',
    ),
    (
      label: 'meal details',
      open: (ApiService service) =>
          MealDetailScreen(apiService: service, mealId: '42'),
      error: 'Could not load meal details.',
      empty: 'Meal not found.',
    ),
    (
      label: 'search',
      open: (ApiService service) => SearchScreen(apiService: service),
      error: 'Could not search recipes.',
      empty: 'No recipes found',
    ),
  ];

  for (final scenario in cases) {
    testWidgets('${scenario.label} handles a fast failed retry and recovers', (
      tester,
    ) async {
      final service = _FailingApiService();
      await tester.pumpWidget(MaterialApp(home: scenario.open(service)));
      if (scenario.label == 'search') {
        await tester.enterText(find.byType(TextField), 'chicken');
        await tester.testTextInput.receiveAction(TextInputAction.search);
      }
      await tester.pumpAndSettle();
      final retry = find.widgetWithText(FilledButton, 'Retry');
      expect(find.text(scenario.error), findsOneWidget);

      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text(scenario.error), findsOneWidget);
      expect(service.attempts, 2);

      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text(scenario.empty), findsOneWidget);
      expect(service.attempts, 3);
    });
  }

  testWidgets(
    'a pending failed lookup can finish after its screen is removed',
    (tester) async {
      final service = _FailingApiService()..attempts = 3;
      await tester.pumpWidget(
        MaterialApp(
          home: MealDetailScreen(apiService: service, mealId: '42'),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      service.lastRequest.completeError(const ApiException('Late failure'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
