import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/culinex_theme.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/primary_action_button.dart';

const List<String> culinexWelcomePhrases = <String>[
  'Turn your ingredients into something delicious.',
  'Snap your ingredients. Get a recipe.',
  'Your next meal starts with a photo.',
  'Got ingredients? We\'ve got ideas.',
  'Find a dish hiding in your fridge.',
  'Cook smarter with what you already have.',
  'From random ingredients to real meals.',
  'Take a photo. Discover what you can cook.',
  'Let\'s cook something great today.',
  'Your kitchen has more potential than you think.',
  'Instant recipe ideas from a single photo.',
  'Smart cooking starts with your camera.',
  'Your ingredients are the beginning, not the problem.',
];

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
  late final String _heroPhrase =
      culinexWelcomePhrases[Random().nextInt(culinexWelcomePhrases.length)];

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LogoLockup(),
              const SizedBox(height: 44),
              Text(
                _heroPhrase,
                style: textTheme.displayMedium?.copyWith(fontSize: 42),
              ),
              const SizedBox(height: 18),
              Text(
                'Show what is in front of you or type what you have, and let Culinex turn it into one clear recipe you can cook right now.',
                style: textTheme.bodyLarge?.copyWith(
                  color: CulinexColors.mutedInk,
                ),
              ),
              const SizedBox(height: 28),
              GlassPanel(
                padding: const EdgeInsets.all(22),
                borderRadius: BorderRadius.circular(30),
                color: CulinexColors.elevatedSurface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HowItWorksStep(
                      number: '1',
                      title: 'Take a photo or type ingredients',
                      description:
                          'Capture the ingredients you already have in a single frame, or skip the camera and enter them yourself.',
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    const _HowItWorksStep(
                      number: '2',
                      title: 'Review the ingredient list',
                      description:
                          'Culinex detects the products from your photo or lets you build the list from scratch.',
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    const _HowItWorksStep(
                      number: '3',
                      title: 'Cook the recipe',
                      description:
                          'Get one smart recipe with ingredients, steps, time, and macros.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              PrimaryActionButton(
                label: 'Take a photo of ingredients',
                icon: Icons.camera_alt_rounded,
                onPressed: widget.onStart,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onStartManualEntry,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Enter ingredients manually'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Best results: use good light and keep every ingredient visible in the frame, or skip the photo and type the ingredients yourself.',
                style: textTheme.bodySmall?.copyWith(
                  color: CulinexColors.mutedInk,
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
          height: 78,
          width: 78,
          decoration: BoxDecoration(
            color: CulinexColors.ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'C',
                style: textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Positioned(
                right: 14,
                top: 14,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Culinex',
                style: textTheme.displaySmall?.copyWith(
                  fontSize: 36,
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

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: CulinexColors.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  color: CulinexColors.mutedInk,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
