import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recipe_explorer/models/category.dart';
import 'package:recipe_explorer/models/meal.dart';
import 'package:recipe_explorer/screens/main_navigation_screen.dart';
import 'package:recipe_explorer/services/api_service.dart';
import 'package:recipe_explorer/services/favorites_controller.dart';
import 'package:recipe_explorer/services/favorites_storage.dart';
import 'package:recipe_explorer/widgets/meal_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _meal = Meal(id: '42', name: 'Roast Chicken', thumbnailUrl: null);

class _ControlledFavoritesStorage extends FavoritesStorage {
  final loadResult = Completer<List<String>>();
  final saveResult = Completer<void>();

  @override
  Future<List<String>> load() => loadResult.future;

  @override
  Future<void> save(List<String> mealIds) => saveResult.future;
}

class _FakeApiService extends ApiService {
  _FakeApiService({this.lookup});

  final Future<Meal?> Function(String)? lookup;

  @override
  Future<List<Category>> fetchCategories() async => [];

  @override
  Future<List<Meal>> fetchMealsByName(String name) async => [_meal];

  @override
  Future<Meal?> fetchMealDetails(String id) async {
    final lookup = this.lookup;
    if (lookup != null) return lookup(id);
    return id == _meal.id ? _meal : null;
  }
}

Future<void> _launch(WidgetTester tester, ApiService service) async {
  await tester.pumpWidget(
    MaterialApp(home: MainNavigationScreen(apiService: service)),
  );
  await tester.pumpAndSettle();
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(NavigationDestination, label));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('rolls back a failed write and permits editing again', () async {
    final storage = _ControlledFavoritesStorage();
    final controller = FavoritesController(storage);
    addTearDown(controller.dispose);
    final load = controller.load();
    storage.loadResult.complete(['42']);
    await load;

    final save = controller.toggle('42');
    expect(controller.mealIds, isEmpty);
    expect(controller.canEdit, isFalse);
    storage.saveResult.completeError(StateError('Write failed'));

    expect(await save, isFalse);
    expect(controller.mealIds, ['42']);
    expect(controller.canEdit, isTrue);
  });

  test('a pending load can finish after the controller is disposed', () async {
    final storage = _ControlledFavoritesStorage();
    final controller = FavoritesController(storage);
    final load = controller.load();
    controller.dispose();
    storage.loadResult.complete(['42']);
    await load;

    expect(controller.canEdit, isFalse);
    expect(await controller.toggle('42'), isFalse);
    await controller.load();
  });

  testWidgets('saves, restores, and removes a favorite through the UI', (
    tester,
  ) async {
    const storage = FavoritesStorage();
    await _launch(tester, _FakeApiService());
    await _tab(tester, 'Search');
    await tester.enterText(find.byType(TextField), 'chicken');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    final mealCard = find.widgetWithText(MealCard, _meal.name).hitTestable();
    await tester.tap(mealCard);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(await storage.load(), [_meal.id]);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await _tab(tester, 'Favorites');
    expect(mealCard, findsOneWidget);

    // Rebuild the app with a new shell and controller using the same store.
    await tester.pumpWidget(const SizedBox.shrink());
    await _launch(tester, _FakeApiService());
    await _tab(tester, 'Favorites');
    expect(mealCard, findsOneWidget);

    await tester.tap(mealCard);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(await storage.load(), isEmpty);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(mealCard, findsNothing);
    expect(find.text('No favorites yet.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _launch(tester, _FakeApiService());
    await _tab(tester, 'Favorites');
    expect(find.text('No favorites yet.'), findsOneWidget);
  });

  testWidgets('retries a failed saved recipe lookup and shows loading', (
    tester,
  ) async {
    await const FavoritesStorage().save([_meal.id]);
    var requests = 0;
    final retry = Completer<Meal?>();
    final service = _FakeApiService(
      lookup: (id) async {
        expect(id, _meal.id);
        if (requests++ == 0) throw const ApiException('Request failed.');
        return retry.future;
      },
    );
    await _launch(tester, service);
    await _tab(tester, 'Favorites');

    expect(find.text('Could not load a saved meal.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await tester.pump();

    expect(requests, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    retry.complete(_meal);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(MealCard, _meal.name), findsOneWidget);
    expect(find.text('Could not load a saved meal.'), findsNothing);
  });
}
