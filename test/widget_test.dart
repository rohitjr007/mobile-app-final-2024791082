import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recipe_explorer/models/category.dart';
import 'package:recipe_explorer/screens/home_screen.dart';
import 'package:recipe_explorer/services/api_service.dart';
import 'package:recipe_explorer/widgets/category_card.dart';

const _categories = [
  Category(
    id: '1',
    name: 'Seafood',
    thumbnailUrl: 'https://example.invalid/seafood.png',
    description: 'Seafood recipes',
  ),
  Category(
    id: '2',
    name: 'Vegetarian',
    thumbnailUrl: 'https://example.invalid/vegetarian.png',
    description: 'Vegetarian recipes',
  ),
];

class _FakeApiService extends ApiService {
  _FakeApiService(this.loadCategories);

  final Future<List<Category>> Function() loadCategories;

  @override
  Future<List<Category>> fetchCategories() => loadCategories();
}

Future<void> _pumpHome(
  WidgetTester tester,
  Future<List<Category>> Function() loadCategories,
) {
  return tester.pumpWidget(
    MaterialApp(home: HomeScreen(apiService: _FakeApiService(loadCategories))),
  );
}

void main() {
  testWidgets('shows the Recipe Explorer title and loads category cards', (
    tester,
  ) async {
    final response = Completer<List<Category>>();
    await _pumpHome(tester, () => response.future);

    expect(find.text('Recipe Explorer'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(CategoryCard), findsNothing);

    response.complete(_categories);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(CategoryCard), findsNWidgets(2));
    expect(find.text('Seafood'), findsOneWidget);
    expect(find.text('Vegetarian'), findsOneWidget);
  });

  testWidgets('shows a load error and fetches categories again on Retry', (
    tester,
  ) async {
    var requests = 0;
    final retryResponse = Completer<List<Category>>();
    await _pumpHome(tester, () async {
      requests++;
      if (requests == 1) throw const ApiException('Request failed.');
      return retryResponse.future;
    });
    await tester.pumpAndSettle();

    expect(find.text('Could not load recipe categories.'), findsOneWidget);
    expect(find.byType(CategoryCard), findsNothing);
    final retryButton = find.widgetWithText(FilledButton, 'Retry');
    expect(retryButton, findsOneWidget);
    expect(requests, 1);

    await tester.tap(retryButton);
    await tester.pump();

    expect(requests, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(retryButton, findsNothing);

    retryResponse.complete(_categories);
    await tester.pumpAndSettle();

    expect(find.byType(CategoryCard), findsNWidgets(2));
    expect(find.text('Could not load recipe categories.'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
