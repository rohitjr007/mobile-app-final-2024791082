class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.category,
    this.area,
    this.instructions,
    this.youtubeUrl,
    this.sourceUrl,
    this.ingredients = const [],
  });

  final String id;
  final String name;
  final String? thumbnailUrl;
  final String? category;
  final String? area;
  final String? instructions;
  final String? youtubeUrl;
  final String? sourceUrl;
  final List<({String name, String? measure})> ingredients;

  factory Meal.fromJson(Map<String, dynamic> json) {
    final id = _optionalText(json['idMeal']);
    final name = _optionalText(json['strMeal']);
    if (id == null || name == null) {
      throw const FormatException('Meal ID and name are required.');
    }

    final ingredients = <({String name, String? measure})>[];
    for (var slot = 1; slot <= 20; slot++) {
      final name = _optionalText(json['strIngredient$slot']);
      if (name != null) {
        ingredients.add((
          name: name,
          measure: _optionalText(json['strMeasure$slot']),
        ));
      }
    }

    return Meal(
      id: id,
      name: name,
      thumbnailUrl: _optionalText(json['strMealThumb']),
      category: _optionalText(json['strCategory']),
      area: _optionalText(json['strArea']),
      instructions: _optionalText(json['strInstructions']),
      youtubeUrl: _optionalText(json['strYoutube']),
      sourceUrl: _optionalText(json['strSource']),
      ingredients: List.unmodifiable(ingredients),
    );
  }

  static String? _optionalText(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}
