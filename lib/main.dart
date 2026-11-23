import 'package:material_ui/material_ui.dart';

import 'screens/main_navigation_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(seedColor: const Color(0xFF2F654C));
    return MaterialApp(
      title: 'Recipe Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colors,
        appBarTheme: AppBarTheme(
          backgroundColor: colors.surfaceContainerLow,
          foregroundColor: colors.onSurface,
          iconTheme: IconThemeData(color: colors.primary),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        iconTheme: IconThemeData(color: colors.onSurfaceVariant),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: colors.surfaceContainerLow,
          indicatorColor: colors.primaryContainer,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            return IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
            );
          }),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}
