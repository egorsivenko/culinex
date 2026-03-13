import 'package:flutter/material.dart';

import '../core/network/culinex_api_client.dart';
import '../core/network/culinex_repository.dart';
import '../core/theme/culinex_theme.dart';
import '../features/camera/camera_capture_screen.dart';
import '../features/home/welcome_screen.dart';
import '../features/ingredients/ingredient_review_screen.dart';
import '../features/ingredients/scan_loading_screen.dart';
import '../features/recipe/recipe_loading_screen.dart';
import '../features/recipe/recipe_screen.dart';
import '../features/session/cook_session_controller.dart';
import '../features/session/session_error_screen.dart';

class CulinexApp extends StatefulWidget {
  const CulinexApp({super.key, this.controller});

  final CookSessionController? controller;

  @override
  State<CulinexApp> createState() => _CulinexAppState();
}

class _CulinexAppState extends State<CulinexApp> {
  late final bool _ownsController;
  late final CookSessionController _controller;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? _buildController();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Culinex',
      theme: buildCulinexTheme(),
      home: CulinexFlowShell(controller: _controller),
    );
  }

  CookSessionController _buildController() {
    final CulinexRepository repository = CulinexApiClient();
    return CookSessionController(repository: repository);
  }
}

class CulinexFlowShell extends StatelessWidget {
  const CulinexFlowShell({required this.controller, super.key});

  final CookSessionController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey(controller.stage),
            child: switch (controller.stage) {
              SessionStage.welcome => WelcomeScreen(
                onStart: controller.openCamera,
              ),
              SessionStage.camera => CameraCaptureScreen(
                onBack: controller.showWelcome,
                onCapture: controller.extractIngredientsFromPhoto,
              ),
              SessionStage.extracting => ScanLoadingScreen(
                imagePath: controller.capturedImagePath,
              ),
              SessionStage.ingredients => IngredientReviewScreen(
                imagePath: controller.capturedImagePath,
                ingredients: controller.ingredients,
                onBack: controller.retakePhoto,
                onProceed: controller.generateRecipe,
                onOpenRecipe: controller.recipe != null
                    ? controller.showRecipe
                    : null,
              ),
              SessionStage.generatingRecipe => RecipeLoadingScreen(
                imagePath: controller.capturedImagePath,
              ),
              SessionStage.recipe => RecipeScreen(
                recipe: controller.recipe!,
                onBackToIngredients: controller.showIngredients,
                onCookAnother: controller.resetSession,
              ),
              SessionStage.error => SessionErrorScreen(
                title: controller.errorTitle,
                message: controller.errorMessage,
                primaryActionLabel: controller.primaryErrorActionLabel,
                secondaryActionLabel: controller.secondaryErrorActionLabel,
                onPrimaryAction: controller.retryLastAction,
                onSecondaryAction: controller.performErrorSecondaryAction,
              ),
            },
          ),
        );
      },
    );
  }
}
