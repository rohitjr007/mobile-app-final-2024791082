class Category {
  const Category({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    required this.description,
  });

  final String id;
  final String name;
  final String? thumbnailUrl;
  final String description;

  factory Category.fromJson(Map<String, dynamic> json) {
    final id = _optionalText(json['idCategory']);
    final name = _optionalText(json['strCategory']);
    if (id == null || name == null) {
      throw const FormatException('Category ID and name are required.');
    }

    return Category(
      id: id,
      name: name,
      thumbnailUrl: _optionalText(json['strCategoryThumb']),
      description: _optionalText(json['strCategoryDescription']) ?? '',
    );
  }

  static String? _optionalText(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}
