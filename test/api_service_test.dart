import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recipe_explorer/services/api_service.dart';

const _summary = {
  'idMeal': '42',
  'strMeal': 'Crème brûlée',
  'strMealThumb': 'https://example.invalid/meal.jpg',
};

http.Response _jsonResponse(Object payload) {
  return http.Response.bytes(utf8.encode(jsonEncode(payload)), 200);
}

void main() {
  test('uses the expected endpoints and decodes meal summaries', () async {
    final requests = <Uri>[];
    final service = ApiService(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.scheme, 'https');
        expect(request.url.host, 'www.themealdb.com');
        requests.add(request.url);
        if (request.url.path.endsWith('/categories.php')) {
          return _jsonResponse({
            'categories': [
              {'idCategory': '1', 'strCategory': 'Seafood'},
            ],
          });
        }
        return _jsonResponse({
          'meals': [_summary],
        });
      }),
    );

    final category = (await service.fetchCategories()).single;
    expect(category.name, 'Seafood');
    expect(category.thumbnailUrl, isNull);
    expect(category.description, isEmpty);
    final filtered = await service.fetchMealsByCategory('Fish & Seafood');
    final found = await service.fetchMealsByName('crème brûlée');
    expect(filtered.single.thumbnailUrl, _summary['strMealThumb']);
    expect(found.single.name, 'Crème brûlée');
    expect((await service.fetchMealDetails('42'))?.id, '42');

    expect(requests.map((uri) => uri.path), [
      '/api/json/v1/1/categories.php',
      '/api/json/v1/1/filter.php',
      '/api/json/v1/1/search.php',
      '/api/json/v1/1/lookup.php',
    ]);
    expect(requests.map((uri) => uri.queryParameters), [
      <String, String>{},
      {'c': 'Fish & Seafood'},
      {'s': 'crème brûlée'},
      {'i': '42'},
    ]);
  });

  test('keeps valid ingredients when optional fields are malformed', () async {
    final service = ApiService(
      client: MockClient(
        (_) async => _jsonResponse({
          'meals': [
            {
              ..._summary,
              'strMealThumb': false,
              'strInstructions': ['invalid'],
              'strIngredient1': ' ',
              'strMeasure1': 'Unused',
              'strIngredient5': 10,
              'strIngredient9': ' Sugar ',
              'strMeasure9': 12,
              'strIngredient20': 'Cream',
              'strMeasure20': ' 1 cup ',
            },
          ],
        }),
      ),
    );

    final meal = await service.fetchMealDetails('42');
    expect(meal?.thumbnailUrl, isNull);
    expect(meal?.instructions, isNull);
    expect(meal?.ingredients, [
      (name: 'Sugar', measure: null),
      (name: 'Cream', measure: '1 cup'),
    ]);
  });

  test('handles empty lists and null meal results', () async {
    final service = ApiService(
      client: MockClient(
        (request) async => _jsonResponse(
          request.url.path.endsWith('/categories.php')
              ? {'categories': []}
              : {'meals': null},
        ),
      ),
    );

    expect(await service.fetchCategories(), isEmpty);
    expect(await service.fetchMealsByCategory('Seafood'), isEmpty);
    expect(await service.fetchMealsByName('missing'), isEmpty);
    expect(await service.fetchMealDetails('missing'), isNull);
  });

  test('reports HTTP and transport failures as ApiException', () async {
    final service = ApiService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/categories.php')) {
          return http.Response('Unavailable', 503);
        }
        throw http.ClientException('Offline', request.url);
      }),
    );

    await expectLater(
      service.fetchCategories(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('503'),
        ),
      ),
    );
    await expectLater(
      service.fetchMealsByName('chicken'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('connect'),
        ),
      ),
    );
  });

  test('reports malformed JSON, envelopes and required fields', () async {
    final bodies = [
      'this is not JSON',
      '{}',
      '{"meals": {}}',
      '{"meals": [42]}',
      '{"meals": [{"idMeal": "42", "strMeal": " " }]}',
      '{"meals": [{"strMeal": "Missing ID"}]}',
    ];

    for (final body in bodies) {
      final service = ApiService(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(
        service.fetchMealDetails('42'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('invalid response'),
          ),
        ),
        reason: body,
      );
    }
  });
}
