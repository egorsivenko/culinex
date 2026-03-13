import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/culinex_theme.dart';

class PhotoBackdrop extends StatelessWidget {
  const PhotoBackdrop({
    required this.child,
    super.key,
    this.imagePath,
    this.blurSigma = 16,
    this.overlayColor = const Color(0x9E000000),
  });

  final String? imagePath;
  final double blurSigma;
  final Color overlayColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: CulinexColors.canvas),
        if (imagePath != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Image.file(
              File(imagePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.expand();
              },
            ),
          ),
        ColoredBox(color: overlayColor),
        child,
      ],
    );
  }
}
