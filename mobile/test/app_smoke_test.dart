import 'package:culinex/app/app.dart';
import 'package:culinex/core/network/culinex_repository.dart';
import 'package:culinex/features/home/welcome_screen.dart';
import 'package:culinex/features/session/culinex_models.dart';
import 'package:culinex/features/session/cook_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app opens on the welcome screen', (tester) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );

    await tester.pumpWidget(CulinexApp(controller: controller));

    expect(find.text('Culinex'), findsOneWidget);
    expect(find.text('Use the camera'), findsOneWidget);
    expect(find.text('Type ingredients'), findsOneWidget);
    expect(find.text('Enter ingredients manually'), findsOneWidget);
    expect(find.text('Choose how to start your recipe'), findsNothing);
    expect(find.text('Take a photo or type ingredients'), findsNothing);
    expect(find.text('Take a photo of ingredients'), findsNothing);
    expect(find.text('How it works'), findsNothing);
    expect(find.text('Show what is in front of you'), findsNothing);
    expect(
      culinexWelcomePhrases.any(
        (String phrase) => find.text(phrase).evaluate().isNotEmpty,
      ),
      isTrue,
    );

    controller.dispose();
  });

  testWidgets('manual entry button opens the ingredient screen', (
    tester,
  ) async {
    final CookSessionController controller = CookSessionController(
      repository: _NoopRepository(),
    );

    await tester.pumpWidget(CulinexApp(controller: controller));
    await tester.ensureVisible(find.text('Type ingredients'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Type ingredients'));
    await tester.pumpAndSettle();

    expect(find.text('Manual entry'), findsOneWidget);
    expect(find.text('Add your ingredients'), findsOneWidget);
    expect(find.text('No ingredients added yet'), findsOneWidget);
    expect(find.text('View original photo'), findsNothing);

    controller.dispose();
  });
}

class _NoopRepository implements CulinexRepository {
  @override
  void close() {}

  @override
  Future<List<ExtractedIngredient>> extractIngredients(imageFile) async {
    return const [];
  }

  @override
  Future<GeneratedRecipe> generateRecipe(RecipeGenerationRequest request) {
    throw UnimplementedError();
  }
}
