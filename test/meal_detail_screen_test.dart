import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recipe_explorer/models/meal.dart';
import 'package:recipe_explorer/screens/meal_detail_screen.dart';
import 'package:recipe_explorer/services/api_service.dart';

const _mealId = '52772';
const _instructions = 'Heat the oil.\nStir in the garlic and serve.';

class _FakeApiService extends ApiService {
  _FakeApiService(this.loadMeal);

  final Future<Meal?> Function() loadMeal;
  final requestedIds = <String>[];

  @override
  Future<Meal?> fetchMealDetails(String id) {
    requestedIds.add(id);
    return loadMeal();
  }
}

Future<void> _pumpDetails(WidgetTester tester, ApiService service) {
  return tester.pumpWidget(
    MaterialApp(
      home: MealDetailScreen(mealId: _mealId, apiService: service),
    ),
  );
}

void main() {
  testWidgets('loads and displays the full recipe on a phone-sized screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 680));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final response = Completer<Meal?>();
    final service = _FakeApiService(() => response.future);
    await _pumpDetails(tester, service);

    expect(service.requestedIds, [_mealId]);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Ingredients'), findsNothing);

    const imageUrl = 'https://example.invalid/recipe.jpg';
    response.complete(
      Meal.fromJson({
        'idMeal': _mealId,
        'strMeal': 'Garlic Pasta',
        'strMealThumb': imageUrl,
        'strCategory': 'Pasta',
        'strArea': 'Italian',
        'strIngredient1': ' Garlic ',
        'strMeasure1': ' 2 cloves ',
        'strInstructions': _instructions,
      }),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, imageUrl);
    expect(find.text('Garlic Pasta'), findsOneWidget);
    expect(find.text('Category: Pasta'), findsOneWidget);
    expect(find.text('Area: Italian'), findsOneWidget);
    expect(find.text('Garlic'), findsOneWidget);
    expect(find.text('2 cloves'), findsOneWidget);
    await tester.scrollUntilVisible(find.text(_instructions), 150);
    expect(find.text(_instructions).hitTestable(), findsOneWidget);
  });

  testWidgets('retries a failed detail lookup for the same meal', (
    tester,
  ) async {
    var attempts = 0;
    final response = Completer<Meal?>();
    final service = _FakeApiService(() async {
      if (attempts++ == 0) throw const ApiException('Request failed.');
      return response.future;
    });
    await _pumpDetails(tester, service);
    await tester.pumpAndSettle();

    expect(find.text('Could not load meal details.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pump();

    expect(service.requestedIds, [_mealId, _mealId]);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.complete(
      const Meal(id: _mealId, name: 'Pasta', thumbnailUrl: null),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pasta'), findsOneWidget);
    expect(find.text('Could not load meal details.'), findsNothing);
  });

  testWidgets('skips blank ingredients and keeps measurements paired by slot', (
    tester,
  ) async {
    final meal = Meal.fromJson({
      'idMeal': _mealId,
      'strMeal': 'Seasoned Pasta',
      'strIngredient1': ' ',
      'strMeasure1': 'Unused amount',
      'strIngredient3': 'Salt',
      'strMeasure3': ' ',
      'strIngredient8': 'Pepper',
      'strIngredient20': 'Olive oil',
      'strMeasure20': '1 tbsp',
    });
    await _pumpDetails(tester, _FakeApiService(() async => meal));
    await tester.pumpAndSettle();

    expect(find.text('Unused amount'), findsNothing);
    final rows = <String, String>{
      'Salt': 'Not specified',
      'Pepper': 'Not specified',
      'Olive oil': '1 tbsp',
    };
    for (final entry in rows.entries) {
      await tester.scrollUntilVisible(find.text(entry.key), 150);
      final row = find.ancestor(
        of: find.text(entry.key),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: row, matching: find.text(entry.value)),
        findsOneWidget,
      );
    }
  });

  testWidgets('shows a not-found message when lookup returns null', (
    tester,
  ) async {
    await _pumpDetails(tester, _FakeApiService(() async => null));
    await tester.pumpAndSettle();

    expect(find.text('Meal not found.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });
}
