import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recipe_explorer/main.dart';
import 'package:recipe_explorer/models/category.dart';
import 'package:recipe_explorer/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApiService extends ApiService {
  const _FakeApiService();

  @override
  Future<List<Category>> fetchCategories() async => [];
}

Future<void> _launch(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp(apiService: _FakeApiService()));
  await tester.pumpAndSettle();
}

Future<void> _openAbout(WidgetTester tester) async {
  await tester.tap(find.byTooltip('About'));
  await tester.pumpAndSettle();
}

Finder _themeAction(String label) {
  return find.descendant(
    of: find.byWidgetPredicate(
      (widget) => widget is Tooltip && widget.message == label,
    ),
    matching: find.byType(IconButton),
  );
}

void _expectTheme(WidgetTester tester, ThemeMode mode, Brightness brightness) {
  expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, mode);
  expect(Theme.of(tester.element(find.byType(AppBar))).brightness, brightness);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('uses accessible moon and sun actions in the shared AppBar', (
    tester,
  ) async {
    await _launch(tester);
    _expectTheme(tester, ThemeMode.light, Brightness.light);
    final moon = _themeAction('Switch to dark mode');
    final sun = _themeAction('Switch to light mode');
    expect(moon, findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.bySemanticsLabel('Switch to dark mode'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'chicken');
    await tester.tap(moon);
    await tester.pumpAndSettle();

    _expectTheme(tester, ThemeMode.dark, Brightness.dark);
    expect(sun, findsOneWidget);
    expect(moon, findsNothing);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(find.bySemanticsLabel('Switch to light mode'), findsOneWidget);
    final navigation = find.byType(NavigationBar);
    expect(Theme.of(tester.element(navigation)).brightness, Brightness.dark);
    expect(tester.widget<NavigationBar>(navigation).selectedIndex, 1);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'chicken',
    );

    await tester.tap(find.widgetWithText(NavigationDestination, 'Favorites'));
    await tester.pumpAndSettle();
    expect(sun, findsOneWidget);
    await _openAbout(tester);
    _expectTheme(tester, ThemeMode.dark, Brightness.dark);
    expect(find.widgetWithText(AppBar, 'About'), findsOneWidget);
    expect(find.text('Student Photo'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(sun, findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Favorites'), findsOneWidget);
    await tester.tap(sun);
    await tester.pumpAndSettle();
    _expectTheme(tester, ThemeMode.light, Brightness.light);
    expect(moon, findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });

  testWidgets('restores dark and light choices after app recreation', (
    tester,
  ) async {
    await _launch(tester);
    await tester.tap(_themeAction('Switch to dark mode'));
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    expect(preferences.getBool('dark_mode'), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await _launch(tester);

    _expectTheme(tester, ThemeMode.dark, Brightness.dark);
    final sun = _themeAction('Switch to light mode');
    expect(sun, findsOneWidget);

    await tester.tap(sun);
    await tester.pumpAndSettle();
    await preferences.reload();
    expect(preferences.getBool('dark_mode'), isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await _launch(tester);
    _expectTheme(tester, ThemeMode.light, Brightness.light);
  });
}
