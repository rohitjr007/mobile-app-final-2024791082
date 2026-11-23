import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recipe_explorer/models/meal.dart';
import 'package:recipe_explorer/screens/meal_detail_screen.dart';
import 'package:recipe_explorer/screens/search_screen.dart';
import 'package:recipe_explorer/services/api_service.dart';
import 'package:recipe_explorer/widgets/meal_card.dart';

const _chicken = Meal(id: '1', name: 'Roast Chicken', thumbnailUrl: null);
const _pasta = Meal(id: '2', name: 'Garlic Pasta', thumbnailUrl: null);

class _FakeApiService extends ApiService {
  _FakeApiService(this.search);

  final Future<List<Meal>> Function(String) search;
  final queries = <String>[];
  final detailIds = <String>[];

  @override
  Future<List<Meal>> fetchMealsByName(String name) {
    queries.add(name);
    return search(name);
  }

  @override
  Future<Meal?> fetchMealDetails(String id) async {
    detailIds.add(id);
    return Meal(id: id, name: 'Full chicken recipe', thumbnailUrl: null);
  }
}

Future<void> _openSearch(WidgetTester tester, ApiService service) {
  return tester.pumpWidget(
    MaterialApp(home: SearchScreen(apiService: service)),
  );
}

Future<void> _submit(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.tap(find.byTooltip('Search'));
  await tester.pump();
}

void main() {
  testWidgets('guides initial input and ignores blank searches', (
    tester,
  ) async {
    final service = _FakeApiService((_) async => []);
    await _openSearch(tester, service);

    expect(find.text('Enter a meal name to find recipes.'), findsOneWidget);
    await _submit(tester, '   ');

    expect(service.queries, isEmpty);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Enter a meal name to find recipes.'), findsOneWidget);
  });

  testWidgets('shows loading and results and opens the selected meal detail', (
    tester,
  ) async {
    final response = Completer<List<Meal>>();
    final service = _FakeApiService((_) => response.future);
    await _openSearch(tester, service);
    await tester.enterText(find.byType(TextField), ' chicken ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(service.queries, ['chicken']);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    response.complete([_chicken]);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    final result = find.widgetWithText(MealCard, _chicken.name);
    expect(result, findsOneWidget);

    await tester.tap(result);
    await tester.pumpAndSettle();

    expect(service.detailIds, [_chicken.id]);
    expect(find.byType(MealDetailScreen), findsOneWidget);
    expect(find.text('Full chicken recipe'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(result, findsOneWidget);
    expect(service.queries, ['chicken']);
  });

  testWidgets('shows a no-results message for an empty response', (
    tester,
  ) async {
    await _openSearch(tester, _FakeApiService((_) async => []));
    await _submit(tester, 'unknown meal');
    await tester.pumpAndSettle();

    expect(find.text('No recipes found'), findsOneWidget);
    expect(find.byType(MealCard), findsNothing);
  });

  testWidgets('retries a failed search with the same query', (tester) async {
    var attempts = 0;
    final service = _FakeApiService((_) async {
      if (attempts++ == 0) throw const ApiException('Search failed.');
      return [_chicken];
    });
    await _openSearch(tester, service);
    await _submit(tester, 'chicken');
    await tester.pumpAndSettle();

    expect(find.text('Could not search recipes.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(service.queries, ['chicken', 'chicken']);
    expect(find.text('Could not search recipes.'), findsNothing);
    expect(find.widgetWithText(MealCard, _chicken.name), findsOneWidget);
  });

  testWidgets('ignores late results and resets when the query is cleared', (
    tester,
  ) async {
    final first = Completer<List<Meal>>();
    final second = Completer<List<Meal>>();
    final service = _FakeApiService(
      (query) => query == 'chicken' ? first.future : second.future,
    );
    await _openSearch(tester, service);
    await _submit(tester, 'chicken');
    await _submit(tester, 'pasta');

    expect(service.queries, ['chicken', 'pasta']);
    second.complete([_pasta]);
    await tester.pumpAndSettle();
    first.complete([_chicken]);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(MealCard, _pasta.name), findsOneWidget);
    expect(find.widgetWithText(MealCard, _chicken.name), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.byType(MealCard), findsNothing);
    expect(find.text('Enter a meal name to find recipes.'), findsOneWidget);
  });
}
