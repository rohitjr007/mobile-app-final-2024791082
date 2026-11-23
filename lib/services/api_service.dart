import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/meal.dart';

class ApiService {
  const ApiService({this._client});

  final http.Client? _client;

  Future<List<Category>> fetchCategories() {
    return _fetchList('categories.php', 'categories', Category.fromJson);
  }

  Future<List<Meal>> fetchMealsByCategory(String category) {
    return _fetchList('filter.php', 'meals', Meal.fromJson, {'c': category});
  }

  /// Returns null when TheMealDB has no meal with this ID.
  Future<Meal?> fetchMealDetails(String id) async {
    final meals = await _fetchList('lookup.php', 'meals', Meal.fromJson, {
      'i': id,
    });
    return meals.firstOrNull;
  }

  Future<List<Meal>> fetchMealsByName(String name) {
    return _fetchList('search.php', 'meals', Meal.fromJson, {'s': name});
  }

  Future<List<T>> _fetchList<T>(
    String endpoint,
    String key,
    T Function(Map<String, dynamic>) fromJson, [
    Map<String, String>? query,
  ]) async {
    final uri = Uri.https(
      'www.themealdb.com',
      '/api/json/v1/1/$endpoint',
      query,
    );

    try {
      final response = await (_client?.get(uri) ?? http.get(uri)).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != 200) {
        throw ApiException('TheMealDB returned HTTP ${response.statusCode}.');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic> || !data.containsKey(key)) {
        throw const FormatException('Missing response field.');
      }
      final entries = data[key] as List<dynamic>?;
      if (entries == null) return <T>[];

      return entries
          .map((entry) => fromJson(entry as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw const ApiException('TheMealDB request timed out.');
    } on http.ClientException {
      throw const ApiException('Could not connect to TheMealDB.');
    } on FormatException {
      throw const ApiException('TheMealDB returned an invalid response.');
    } on TypeError {
      throw const ApiException('TheMealDB returned an invalid response.');
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
