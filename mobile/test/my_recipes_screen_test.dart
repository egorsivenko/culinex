import 'package:culinex/features/recipes/my_recipes_screen.dart';
import 'package:culinex/features/session/culinex_models.dart';
import 'package:culinex/features/session/cook_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets(
    'long press reveals delete action and removes row after confirm',
    (tester) async {
      List<RecipeSummary> recipes = const <RecipeSummary>[
        RecipeSummary(
          id: 'recipe-1',
          dishName: 'Tomato Pasta',
          dishDescription: 'Simple dinner',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 20,
        ),
        RecipeSummary(
          id: 'recipe-2',
          dishName: 'Egg Toast',
          dishDescription: 'Fast breakfast',
          difficulty: RecipeDifficulty.easy,
          cookingTimeMinutes: 8,
        ),
      ];
      String? selectedRecipeActionId;
      String? deletedRecipeId;

      await tester.pumpWidget(
        buildLocalizedApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return MyRecipesScreen(
                  status: RecipeHistoryStatus.loaded,
                  recipes: recipes,
                  isOpeningRecipe: false,
                  selectedRecipeActionId: selectedRecipeActionId,
                  deletingRecipeId: null,
                  onRetry: () {},
                  onOpenRecipe: (_) {},
                  onSelectRecipeActions: (String id) {
                    setState(() {
                      selectedRecipeActionId = id;
                    });
                  },
                  onClearRecipeActions: () {
                    setState(() {
                      selectedRecipeActionId = null;
                    });
                  },
                  onDeleteRecipe: (String id) async {
                    setState(() {
                      deletedRecipeId = id;
                      selectedRecipeActionId = null;
                      recipes = recipes
                          .where((RecipeSummary recipe) => recipe.id != id)
                          .toList(growable: false);
                    });
                    return true;
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder recipeList = find.byType(ListView);
      final double listTopBeforeSelection = tester.getTopLeft(recipeList).dy;

      final Finder tomatoRow = find
          .ancestor(
            of: find.text('Tomato Pasta'),
            matching: find.byType(InkWell),
          )
          .first;

      await tester.longPress(tomatoRow);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('recipe-action-box')),
        findsOneWidget,
      );
      expect(find.text('Delete'), findsOneWidget);
      final Finder actionBox = find.byKey(
        const ValueKey<String>('recipe-action-box'),
      );
      expect(tester.getTopLeft(recipeList).dy, listTopBeforeSelection);
      expect(
        tester.getTopLeft(actionBox).dy,
        greaterThan(tester.getBottomLeft(tomatoRow).dy),
      );
      expect(
        tester.getBottomRight(actionBox).dy,
        lessThanOrEqualTo(tester.getBottomRight(recipeList).dy),
      );
      expect(
        tester.getSize(actionBox).width,
        lessThan(tester.getSize(recipeList).width),
      );
      expect(
        find.descendant(of: actionBox, matching: find.byType(TextButton)),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('recipe-delete-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete recipe?'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('delete-recipe-close-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('delete-recipe-confirm-button')),
      );
      await tester.pumpAndSettle();

      expect(deletedRecipeId, 'recipe-1');
      expect(find.text('Tomato Pasta'), findsNothing);
      expect(find.text('Egg Toast'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('recipe-action-box')),
        findsNothing,
      );
    },
  );
}
