import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:culinex/core/auth/auth_session_coordinator.dart';
import 'package:culinex/core/network/culinex_api_client.dart';
import 'package:culinex/features/session/culinex_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'generateRecipe attaches bearer token and refreshes once on 401',
    () async {
      final _FakeAuthSessionCoordinator authSessionCoordinator =
          _FakeAuthSessionCoordinator(
            accessToken: 'expired-access-token',
            refreshedAccessToken: 'fresh-access-token',
          );
      int requestCount = 0;
      final CulinexApiClient client = CulinexApiClient(
        authSessionCoordinator: authSessionCoordinator,
        apiBaseUri: Uri.parse('http://127.0.0.1:8080/api/'),
        client: MockClient((http.Request request) async {
          requestCount += 1;
          expect(
            request.url.toString(),
            'http://127.0.0.1:8080/api/generate-recipe',
          );

          if (requestCount == 1) {
            expect(
              request.headers['Authorization'],
              'Bearer expired-access-token',
            );
            return http.Response('', 401);
          }

          expect(request.headers['Authorization'], 'Bearer fresh-access-token');
          return http.Response(
            jsonEncode(<String, dynamic>{
              'dish_name': 'Tomato Pasta',
              'dish_description': 'Simple dinner',
              'difficulty': 'easy',
              'cooking_time_minutes': 20,
              'ingredients': <Map<String, dynamic>>[
                <String, dynamic>{'name': 'Tomatoes', 'quantity': '2'},
              ],
              'steps': <String>['Boil pasta', 'Add tomatoes'],
              'macros': <String, dynamic>{
                'calories_kcal': 320,
                'protein_g': 12,
                'carbs_g': 54,
                'fat_g': 8,
              },
            }),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final GeneratedRecipe recipe = await client.generateRecipe(
        RecipeGenerationRequest(
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(name: 'Tomatoes', quantity: '2'),
          ],
          assumeBasicStaples: true,
        ),
        locale: const Locale('en'),
      );

      expect(recipe.dishName, 'Tomato Pasta');
      expect(requestCount, 2);
      expect(authSessionCoordinator.refreshCalls, 1);
      client.close();
    },
  );

  test('generateRecipe maps invalid ingredients response', () async {
    final _FakeAuthSessionCoordinator authSessionCoordinator =
        _FakeAuthSessionCoordinator(
          accessToken: 'access-token',
          refreshedAccessToken: 'fresh-access-token',
        );
    final CulinexApiClient client = CulinexApiClient(
      authSessionCoordinator: authSessionCoordinator,
      apiBaseUri: Uri.parse('http://127.0.0.1:8080/api/'),
      client: MockClient((http.Request request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://127.0.0.1:8080/api/generate-recipe',
        );

        return http.Response(
          jsonEncode(<String, dynamic>{
            'error': <String, dynamic>{
              'code': 'invalid_ingredients',
              'message': 'No usable ingredients were provided',
            },
          }),
          422,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    expect(
      () => client.generateRecipe(
        RecipeGenerationRequest(
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(name: 'adadsa', quantity: 'adadad'),
            RecipeIngredient(name: 'qweqwe', quantity: 'zxczxc'),
          ],
          assumeBasicStaples: true,
        ),
        locale: const Locale('en'),
      ),
      throwsA(
        isA<CulinexApiException>().having(
          (error) => error.code,
          'code',
          CulinexApiErrorCode.invalidIngredients,
        ),
      ),
    );

    client.close();
  });

  test(
    'extractIngredients attaches bearer token to multipart requests',
    () async {
      final _FakeAuthSessionCoordinator authSessionCoordinator =
          _FakeAuthSessionCoordinator(
            accessToken: 'access-token',
            refreshedAccessToken: 'fresh-access-token',
          );
      final File imageFile = await _createTempImageFile();
      final CulinexApiClient client = CulinexApiClient(
        authSessionCoordinator: authSessionCoordinator,
        apiBaseUri: Uri.parse('http://127.0.0.1:8080/api/'),
        client: MockClient((http.BaseRequest request) async {
          expect(request.method, 'POST');
          expect(
            request.url.toString(),
            'http://127.0.0.1:8080/api/extract-ingredients',
          );
          expect(request.headers['Authorization'], 'Bearer access-token');

          return http.Response(
            jsonEncode(<String, dynamic>{
              'ingredients': <Map<String, dynamic>>[
                <String, dynamic>{
                  'name': 'Tomatoes',
                  'quantity': '2',
                  'confidence': 'high',
                },
              ],
            }),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final List<ExtractedIngredient> ingredients = await client
          .extractIngredients(imageFile, locale: const Locale('en'));

      expect(ingredients, hasLength(1));
      expect(ingredients.first.name, 'Tomatoes');
      client.close();
      await imageFile.parent.delete(recursive: true);
    },
  );

  test('listRecipes decodes recipe summaries', () async {
    final _FakeAuthSessionCoordinator authSessionCoordinator =
        _FakeAuthSessionCoordinator(
          accessToken: 'access-token',
          refreshedAccessToken: 'fresh-access-token',
        );
    final CulinexApiClient client = CulinexApiClient(
      authSessionCoordinator: authSessionCoordinator,
      apiBaseUri: Uri.parse('http://127.0.0.1:8080/api/'),
      client: MockClient((http.Request request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://127.0.0.1:8080/api/recipes');
        expect(request.headers['Authorization'], 'Bearer access-token');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'recipes': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'recipe-1',
                'dish_name': 'Tomato Pasta',
                'dish_description': 'Simple dinner',
                'difficulty': 'easy',
                'cooking_time_minutes': 20,
                'is_favorite': true,
                'created_at': '2026-04-21T12:00:00Z',
              },
            ],
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    final List<RecipeSummary> recipes = await client.listRecipes();

    expect(recipes, hasLength(1));
    expect(recipes.single.id, 'recipe-1');
    expect(recipes.single.dishName, 'Tomato Pasta');
    expect(recipes.single.isFavorite, isTrue);
    expect(recipes.single.createdAt, DateTime.utc(2026, 4, 21, 12));
    client.close();
  });

  test('getRecipe decodes a saved recipe', () async {
    final _FakeAuthSessionCoordinator authSessionCoordinator =
        _FakeAuthSessionCoordinator(
          accessToken: 'access-token',
          refreshedAccessToken: 'fresh-access-token',
        );
    final CulinexApiClient client = CulinexApiClient(
      authSessionCoordinator: authSessionCoordinator,
      apiBaseUri: Uri.parse('http://127.0.0.1:8080/api/'),
      client: MockClient((http.Request request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'http://127.0.0.1:8080/api/recipes/recipe-1',
        );
        expect(request.headers['Authorization'], 'Bearer access-token');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'id': 'recipe-1',
            'dish_name': 'Tomato Pasta',
            'dish_description': 'Simple dinner',
            'difficulty': 'easy',
            'cooking_time_minutes': 20,
            'is_favorite': true,
            'ingredients': <Map<String, dynamic>>[
              <String, dynamic>{'name': 'Tomatoes', 'quantity': '2'},
            ],
            'steps': <String>['Boil pasta', 'Add tomatoes'],
            'macros': <String, dynamic>{
              'calories_kcal': 320,
              'protein_g': 12,
              'carbs_g': 54,
              'fat_g': 8,
            },
            'created_at': '2026-04-21T12:00:00Z',
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    final GeneratedRecipe recipe = await client.getRecipe('recipe-1');

    expect(recipe.id, 'recipe-1');
    expect(recipe.dishName, 'Tomato Pasta');
    expect(recipe.isFavorite, isTrue);
    expect(recipe.createdAt, DateTime.utc(2026, 4, 21, 12));
    client.close();
  });

  test(
    'setRecipeFavorite sends authorized patch and refreshes once on 401',
    () async {
      final _FakeAuthSessionCoordinator authSessionCoordinator =
          _FakeAuthSessionCoordinator(
            accessToken: 'expired-access-token',
            refreshedAccessToken: 'fresh-access-token',
          );
      int requestCount = 0;
      final CulinexApiClient client = CulinexApiClient(
        authSessionCoordinator: authSessionCoordinator,
        apiBaseUri: Uri.parse('http://127.0.0.1:8080/api/'),
        client: MockClient((http.Request request) async {
          requestCount += 1;
          expect(request.method, 'PATCH');
          expect(
            request.url.toString(),
            'http://127.0.0.1:8080/api/recipes/recipe-1/favorite',
          );
          expect(request.headers['Content-Type'], 'application/json');
          expect(jsonDecode(request.body), <String, dynamic>{
            'is_favorite': true,
          });

          if (requestCount == 1) {
            expect(
              request.headers['Authorization'],
              'Bearer expired-access-token',
            );
            return http.Response('', 401);
          }

          expect(request.headers['Authorization'], 'Bearer fresh-access-token');
          return http.Response('', 204);
        }),
      );

      await client.setRecipeFavorite('recipe-1', true);

      expect(requestCount, 2);
      expect(authSessionCoordinator.refreshCalls, 1);
      client.close();
    },
  );

  test(
    'deleteAllRecipes sends authorized delete and refreshes once on 401',
    () async {
      final _FakeAuthSessionCoordinator authSessionCoordinator =
          _FakeAuthSessionCoordinator(
            accessToken: 'expired-access-token',
            refreshedAccessToken: 'fresh-access-token',
          );
      int requestCount = 0;
      final CulinexApiClient client = CulinexApiClient(
        authSessionCoordinator: authSessionCoordinator,
        apiBaseUri: Uri.parse('http://127.0.0.1:8080/api/'),
        client: MockClient((http.Request request) async {
          requestCount += 1;
          expect(request.method, 'DELETE');
          expect(request.url.toString(), 'http://127.0.0.1:8080/api/recipes');

          if (requestCount == 1) {
            expect(
              request.headers['Authorization'],
              'Bearer expired-access-token',
            );
            return http.Response('', 401);
          }

          expect(request.headers['Authorization'], 'Bearer fresh-access-token');
          return http.Response('', 204);
        }),
      );

      await client.deleteAllRecipes();

      expect(requestCount, 2);
      expect(authSessionCoordinator.refreshCalls, 1);
      client.close();
    },
  );

  test(
    'deleteRecipe sends authorized delete and refreshes once on 401',
    () async {
      final _FakeAuthSessionCoordinator authSessionCoordinator =
          _FakeAuthSessionCoordinator(
            accessToken: 'expired-access-token',
            refreshedAccessToken: 'fresh-access-token',
          );
      int requestCount = 0;
      final CulinexApiClient client = CulinexApiClient(
        authSessionCoordinator: authSessionCoordinator,
        apiBaseUri: Uri.parse('http://127.0.0.1:8080/api/'),
        client: MockClient((http.Request request) async {
          requestCount += 1;
          expect(request.method, 'DELETE');
          expect(
            request.url.toString(),
            'http://127.0.0.1:8080/api/recipes/recipe-1',
          );

          if (requestCount == 1) {
            expect(
              request.headers['Authorization'],
              'Bearer expired-access-token',
            );
            return http.Response('', 401);
          }

          expect(request.headers['Authorization'], 'Bearer fresh-access-token');
          return http.Response('', 204);
        }),
      );

      await client.deleteRecipe('recipe-1');

      expect(requestCount, 2);
      expect(authSessionCoordinator.refreshCalls, 1);
      client.close();
    },
  );
}

class _FakeAuthSessionCoordinator implements AuthSessionCoordinator {
  _FakeAuthSessionCoordinator({
    required this.accessToken,
    required this.refreshedAccessToken,
  });

  final String accessToken;
  final String refreshedAccessToken;
  int refreshCalls = 0;
  bool unauthorizedHandled = false;

  @override
  Future<String> getValidAccessToken() async {
    return accessToken;
  }

  @override
  Future<void> handleUnauthorized() async {
    unauthorizedHandled = true;
  }

  @override
  Future<String> refreshAccessToken() async {
    refreshCalls += 1;
    return refreshedAccessToken;
  }
}

Future<File> _createTempImageFile() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'culinex-auth-test',
  );
  final File file = File('${directory.path}/ingredients.jpg');
  await file.writeAsBytes(<int>[0, 1, 2, 3]);
  return file;
}
