import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recipe_explorer/main.dart';
import 'package:recipe_explorer/models/category.dart';
import 'package:recipe_explorer/models/meal.dart';
import 'package:recipe_explorer/services/api_service.dart';
import 'package:recipe_explorer/widgets/category_card.dart';
import 'package:recipe_explorer/widgets/meal_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _categoryName = 'Seasonal recipes for sharing with family and friends';
const _mealName =
    'Roasted vegetable and chickpea stew with fresh herbs and lemon';
final _instructions = List.filled(
  20,
  'Roast the vegetables until tender, then simmer with chickpeas and herbs.',
).join('\n\n');

class _FakeApiService extends ApiService {
  const _FakeApiService();

  @override
  Future<List<Category>> fetchCategories() async => const [
    Category(
      id: '1',
      name: _categoryName,
      thumbnailUrl: 'https://example.invalid/category.jpeg',
      description: '',
    ),
  ];

  @override
  Future<List<Meal>> fetchMealsByCategory(String category) async => const [
    Meal(id: '1', name: _mealName, thumbnailUrl: null),
  ];

  @override
  Future<Meal?> fetchMealDetails(String id) async => Meal(
    id: id,
    name: _mealName,
    thumbnailUrl: null,
    instructions: _instructions,
  );
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'long recipes and About work at large text in ${brightness.name} mode',
      (tester) async {
        tester.view.physicalSize = const Size(320, 520);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        SharedPreferences.setMockInitialValues({
          'dark_mode': brightness == Brightness.dark,
        });

        await tester.pumpWidget(const MyApp(apiService: _FakeApiService()));
        await tester.pumpAndSettle();

        final category = find.widgetWithText(CategoryCard, _categoryName);
        expect(find.bySemanticsLabel(_categoryName), findsOneWidget);
        await _tap(tester, category);
        final heading = find.widgetWithText(AppBar, _categoryName);
        expect(heading, findsOneWidget);
        expect(
          tester.widget<Text>(find.text(_categoryName)).overflow,
          TextOverflow.ellipsis,
        );

        final meal = find.widgetWithText(MealCard, _mealName);
        expect(tester.widget<Text>(find.text(_mealName)).maxLines, isNull);
        await _tap(tester, meal);
        expect(find.bySemanticsLabel('Add to favorites'), findsOneWidget);
        expect(find.widgetWithText(AppBar, 'Meal details'), findsOneWidget);

        await tester.scrollUntilVisible(find.text(_instructions), 180);
        final instructions = tester.widget<Text>(find.text(_instructions));
        expect(instructions.maxLines, isNull);
        expect(
          Theme.of(tester.element(find.text(_instructions))).brightness,
          brightness,
        );

        await _tap(tester, find.byType(BackButton));
        await _tap(tester, find.byType(BackButton));
        expect(find.bySemanticsLabel('About'), findsOneWidget);
        await _tap(tester, find.byTooltip('About'));
        await tester.scrollUntilVisible(find.byType(ClipOval), 160);
        expect(find.byType(ClipOval).hitTestable(), findsOneWidget);
        final studentId = find.text('2024791082');
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(
          tester
              .getRect(find.byType(ListView))
              .contains(tester.getCenter(studentId)),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
