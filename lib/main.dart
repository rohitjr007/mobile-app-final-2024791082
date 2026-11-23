import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_navigation_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.apiService = const ApiService()});

  final ApiService apiService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _darkModeKey = 'dark_mode';
  static final _lightTheme = _buildTheme(Brightness.light);
  static final _darkTheme = _buildTheme(Brightness.dark);
  late final Future<SharedPreferences> _preferences;
  Future<bool> _lastThemeWrite = Future.value(true);
  bool? _darkMode;

  @override
  void initState() {
    super.initState();
    _preferences = SharedPreferences.getInstance();
  }

  Future<bool> _setDarkMode(bool enabled, SharedPreferences? preferences) {
    setState(() {
      _darkMode = enabled;
    });

    // Persist rapid changes in the same order that the user made them.
    final write = _lastThemeWrite.then((_) async {
      if (preferences == null) return false;
      try {
        return await preferences.setBool(_darkModeKey, enabled);
      } catch (_) {
        return false;
      }
    });
    _lastThemeWrite = write;
    return write;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _preferences,
      builder: (context, snapshot) {
        // Wait for the saved preference before showing the first themed frame.
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final preferences = snapshot.data;
        final darkMode = _darkMode ?? (preferences?.get(_darkModeKey) == true);
        return MaterialApp(
          title: 'Recipe Explorer',
          debugShowCheckedModeBanner: false,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
          home: MainNavigationScreen(
            apiService: widget.apiService,
            onDarkModeChanged: (enabled) => _setDarkMode(enabled, preferences),
          ),
        );
      },
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2F654C),
      brightness: brightness,
    );
    return ThemeData(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }
}
