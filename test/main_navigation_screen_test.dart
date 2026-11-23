import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recipe_explorer/models/category.dart';
import 'package:recipe_explorer/models/meal.dart';
import 'package:recipe_explorer/screens/main_navigation_screen.dart';
import 'package:recipe_explorer/services/api_service.dart';
import 'package:recipe_explorer/widgets/category_card.dart';
import 'package:recipe_explorer/widgets/meal_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _salmon = Meal(id: '1', name: 'Grilled Salmon', thumbnailUrl: null);
const _chicken = Meal(id: '2', name: 'Roast Chicken', thumbnailUrl: null);

class _FakeApiService extends ApiService {
  int categoryLoads = 0;
  final categoryRequests = <String>[];
  final searches = <String>[];
  final detailRequests = <String>[];

  @override
  Future<List<Category>> fetchCategories() async {
    categoryLoads++;
    return const [
      Category(
        id: '1',
        name: 'Seafood',
        thumbnailUrl: 'https://example.invalid/seafood.png',
        description: 'Seafood recipes',
      ),
    ];
  }

  @override
  Future<List<Meal>> fetchMealsByCategory(String category) async {
    categoryRequests.add(category);
    return [_salmon];
  }

  @override
  Future<List<Meal>> fetchMealsByName(String name) async {
    searches.add(name);
    return [_chicken];
  }

  @override
  Future<Meal?> fetchMealDetails(String id) async {
    detailRequests.add(id);
    return Meal(
      id: id,
      name: id == _salmon.id ? 'Full salmon recipe' : 'Full chicken recipe',
      thumbnailUrl: null,
    );
  }
}

Future<void> _openShell(WidgetTester tester, ApiService service) async {
  await tester.pumpWidget(
    MaterialApp(home: MainNavigationScreen(apiService: service)),
  );
  await tester.pumpAndSettle();
}

Future<void> _selectTab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(NavigationDestination, label));
  await tester.pumpAndSettle();
}

Future<void> _goBack(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('opens About, shows the student profile, and returns to Search', (
    tester,
  ) async {
    await _openShell(tester, _FakeApiService());
    await _selectTab(tester, 'Search');
    await tester.enterText(find.byType(TextField), 'chicken');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('About'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'About'), findsOneWidget);
    expect(find.text('Recipe Explorer'), findsOneWidget);
    expect(find.textContaining('Recipes from TheMealDB'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    const details = {
      'Student Name': 'Sarina Karki',
      'Student ID': '2024791082',
    };
    for (final detail in details.entries) {
      final tile = find.widgetWithText(ListTile, detail.key);
      expect(
        find.descendant(of: tile, matching: find.text(detail.value)),
        findsOneWidget,
      );
    }
    expect(find.text('Student Photo'), findsOneWidget);
    final photo = find.descendant(
      of: find.byType(ClipOval),
      matching: find.byType(Image),
    );
    final image = tester.widget<Image>(photo);
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/student_photo.jpeg',
    );
    expect(image.fit, BoxFit.cover);

    await _goBack(tester);

    expect(find.widgetWithText(AppBar, 'Search recipes'), findsOneWidget);
    expect(
      find.widgetWithText(MealCard, _chicken.name).hitTestable(),
      findsOneWidget,
    );
    final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navigation.selectedIndex, 1);
    expect(navigation.destinations, hasLength(3));
  });

  testWidgets('switches among Home, Search, and the empty Favorites tab', (
    tester,
  ) async {
    final service = _FakeApiService();
    await _openShell(tester, service);

    expect(find.widgetWithText(AppBar, 'Recipe Explorer'), findsOneWidget);
    expect(find.widgetWithText(CategoryCard, 'Seafood'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await _selectTab(tester, 'Search');
    expect(find.widgetWithText(AppBar, 'Search recipes'), findsOneWidget);
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);

    await _selectTab(tester, 'Favorites');
    expect(find.widgetWithText(AppBar, 'Favorites'), findsOneWidget);
    expect(find.text('No favorites yet.'), findsOneWidget);
    expect(find.byType(TextField).hitTestable(), findsNothing);

    await _selectTab(tester, 'Home');
    expect(find.widgetWithText(CategoryCard, 'Seafood'), findsOneWidget);
    expect(service.categoryLoads, 1);
  });

  testWidgets('returns from a category meal detail through the list to Home', (
    tester,
  ) async {
    final service = _FakeApiService();
    await _openShell(tester, service);
    await tester.tap(find.widgetWithText(CategoryCard, 'Seafood'));
    await tester.pumpAndSettle();

    expect(service.categoryRequests, ['Seafood']);
    expect(find.widgetWithText(AppBar, 'Seafood'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.widgetWithText(MealCard, _salmon.name));
    await tester.pumpAndSettle();

    expect(service.detailRequests, [_salmon.id]);
    expect(find.text('Full salmon recipe'), findsOneWidget);

    await _goBack(tester);
    expect(find.widgetWithText(AppBar, 'Seafood'), findsOneWidget);
    await _goBack(tester);
    expect(find.widgetWithText(AppBar, 'Recipe Explorer'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('preserves the search and returns to Search from meal details', (
    tester,
  ) async {
    final service = _FakeApiService();
    await _openShell(tester, service);
    await _selectTab(tester, 'Search');
    await tester.enterText(find.byType(TextField), 'chicken');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    final result = find.widgetWithText(MealCard, _chicken.name);
    expect(result.hitTestable(), findsOneWidget);
    await _selectTab(tester, 'Favorites');
    expect(result.hitTestable(), findsNothing);
    await _selectTab(tester, 'Search');

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'chicken',
    );
    expect(result.hitTestable(), findsOneWidget);
    expect(service.searches, ['chicken']);

    await tester.tap(result);
    await tester.pumpAndSettle();
    expect(service.detailRequests, [_chicken.id]);
    expect(find.text('Full chicken recipe'), findsOneWidget);

    await _goBack(tester);
    expect(result.hitTestable(), findsOneWidget);
    expect(service.searches, ['chicken']);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });
}
