import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/culinex_theme.dart';
import '../../core/widgets/primary_action_button.dart';

const List<String> culinexWelcomePhrases = <String>[
  'Turn ingredients into flavor.',
  'Snap your ingredients. Get a recipe.',
  'Your next meal starts with a photo.',
  'Got ingredients? We\'ve got ideas.',
  'Cook more with what you have.',
  'Snap a photo. Start cooking.',
  'Let\'s cook something great today.',
  'Your kitchen has endless potential.',
  'Your kitchen has hidden potential.',
  'Recipe ideas from one photo.',
  'Smart cooking starts here.',
];

final Random _culinexWelcomePhraseRandom = Random();
int _lastCulinexWelcomePhraseIndex = -1;

String _nextWelcomePhrase() {
  final bool hasValidPreviousIndex =
      _lastCulinexWelcomePhraseIndex >= 0 &&
      _lastCulinexWelcomePhraseIndex < culinexWelcomePhrases.length;

  final int nextIndex;
  if (!hasValidPreviousIndex) {
    nextIndex = _culinexWelcomePhraseRandom.nextInt(
      culinexWelcomePhrases.length,
    );
  } else {
    final int rawIndex = _culinexWelcomePhraseRandom.nextInt(
      culinexWelcomePhrases.length - 1,
    );
    nextIndex = rawIndex >= _lastCulinexWelcomePhraseIndex
        ? rawIndex + 1
        : rawIndex;
  }

  _lastCulinexWelcomePhraseIndex = nextIndex;
  return culinexWelcomePhrases[nextIndex];
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    required this.onStart,
    required this.onStartManualEntry,
    super.key,
  });

  final VoidCallback onStart;
  final VoidCallback onStartManualEntry;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final String _heroPhrase = _nextWelcomePhrase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LogoLockup(),
              const SizedBox(height: 28),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool isWideLayout =
                        constraints.maxWidth >= 720 ||
                        constraints.maxWidth > constraints.maxHeight;

                    return Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: isWideLayout ? 760 : 392,
                          child: _WelcomeChoiceLayout(
                            isWideLayout: isWideLayout,
                            heroPhrase: _heroPhrase,
                            onStart: widget.onStart,
                            onStartManualEntry: widget.onStartManualEntry,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoLockup extends StatelessWidget {
  const _LogoLockup();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: CulinexColors.ink,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Image.asset(
            'assets/icon/icon_transparent.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Culinex',
                style: textTheme.displaySmall?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: CulinexColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeChoiceLayout extends StatelessWidget {
  const _WelcomeChoiceLayout({
    required this.isWideLayout,
    required this.heroPhrase,
    required this.onStart,
    required this.onStartManualEntry,
  });

  final bool isWideLayout;
  final String heroPhrase;
  final VoidCallback onStart;
  final VoidCallback onStartManualEntry;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget photoCard = _RecipeModeCard(
      title: 'Take a photo',
      description:
          'Point your camera at the ingredients you already have and let Culinex turn what it sees into one clear recipe.',
      button: PrimaryActionButton(
        label: 'Use the camera',
        icon: Icons.camera_alt_rounded,
        onPressed: onStart,
      ),
    );
    final Widget manualCard = _RecipeModeCard(
      title: 'Enter ingredients manually',
      description:
          'Type the ingredients yourself when you already know the list and want to go straight to a recipe.',
      button: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onStartManualEntry,
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Type ingredients'),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            heroPhrase,
            style: textTheme.displayMedium?.copyWith(fontSize: 36),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Scan ingredients with your camera or type them in to get one smart recipe in seconds.',
              style: textTheme.bodyLarge?.copyWith(
                color: CulinexColors.mutedInk,
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        if (isWideLayout)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: photoCard),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(width: 132, child: _ChoiceSeparator()),
              ),
              Expanded(child: manualCard),
            ],
          )
        else
          Column(
            children: [
              photoCard,
              const SizedBox(height: 12),
              const SizedBox(width: double.infinity, child: _ChoiceSeparator()),
              const SizedBox(height: 12),
              manualCard,
            ],
          ),
      ],
    );
  }
}

class _ChoiceSeparator extends StatelessWidget {
  const _ChoiceSeparator();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        const Expanded(
          child: SizedBox(
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: CulinexColors.border),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'or',
          style: textTheme.titleMedium?.copyWith(
            color: CulinexColors.subtleInk,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: SizedBox(
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: CulinexColors.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecipeModeCard extends StatelessWidget {
  const _RecipeModeCard({
    required this.title,
    required this.description,
    required this.button,
  });

  final String title;
  final String description;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: CulinexColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: CulinexColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 240),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 22, 26, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: CulinexColors.mutedInk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              button,
            ],
          ),
        ),
      ),
    );
  }
}
