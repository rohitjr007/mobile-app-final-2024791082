import 'package:shared_preferences/shared_preferences.dart';

class FavoritesStorage {
  const FavoritesStorage();

  static const _key = 'favorite_meal_ids';

  Future<List<String>> load() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    return preferences.getStringList(_key) ?? [];
  }

  Future<void> save(List<String> mealIds) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setStringList(_key, mealIds)) {
      throw StateError('Could not save favorite meal IDs.');
    }
  }
}
