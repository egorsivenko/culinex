import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/pulse_dots_indicator.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({
    required this.onBack,
    required this.onCapture,
    super.key,
  });

  final VoidCallback onBack;
  final Future<void> Function(String imagePath) onCapture;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  static const Duration _infoPopupVisibilityDuration = Duration(seconds: 3);
  static const Duration _infoPopupFadeDuration = Duration(milliseconds: 300);

  CameraController? _cameraController;
  CameraDescription? _selectedCamera;
  List<CameraDescription> _availableCameras = const [];
  FlashMode _flashMode = FlashMode.off;
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _infoPopupFadeTimer;
  Timer? _infoPopupHideTimer;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isPickingImage = false;
  bool _isInfoPopupMounted = false;
  bool _isInfoPopupVisible = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _showInfoPopup();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _infoPopupFadeTimer?.cancel();
    _infoPopupHideTimer?.cancel();
    _disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeCamera(preferredCamera: _selectedCamera);
      return;
    }

    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _disposeController();
      return;
    }
  }

  Future<void> _initializeCamera({CameraDescription? preferredCamera}) async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'No camera is available on this device.';
        });
        return;
      }

      final CameraDescription nextCamera =
          preferredCamera ??
          _availableCameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => _availableCameras.first,
          );

      final CameraController controller = CameraController(
        nextCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(_flashMode);

      final CameraController? previousController = _cameraController;
      _cameraController = controller;
      _selectedCamera = nextCamera;
      await previousController?.dispose();

      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
        _errorMessage = _readableCameraError(error);
      });
    }
  }

  Future<void> _toggleFlash() async {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final FlashMode nextFlashMode = _flashMode == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;

    try {
      await controller.setFlashMode(nextFlashMode);
      if (!mounted) {
        return;
      }

      setState(() {
        _flashMode = nextFlashMode;
      });
    } on CameraException {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Flash is not available on this device.';
      });
    }
  }

  Future<void> _capturePhoto() async {
    final CameraController? controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing ||
        _isPickingImage ||
        _isInitializing) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    try {
      final XFile file = await controller.takePicture();
      if (!mounted) {
        return;
      }

      await widget.onCapture(file.path);
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _readableCameraError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing || _isPickingImage || _isInitializing) {
      return;
    }

    setState(() {
      _isPickingImage = true;
      _errorMessage = null;
    });

    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (!mounted || file == null) {
        return;
      }

      await widget.onCapture(file.path);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'The selected photo could not be opened. Please try another image.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _disposeController() async {
    final CameraController? controller = _cameraController;
    _cameraController = null;
    await controller?.dispose();
  }

  String _readableCameraError(CameraException error) {
    return switch (error.code) {
      'CameraAccessDenied' =>
        'Camera permission was denied. Enable it in system settings.',
      'CameraAccessRestricted' => 'Camera access is restricted on this device.',
      'AudioAccessDenied' => 'Microphone access was denied.',
      _ => 'The camera could not be started. Please try again.',
    };
  }

  void _showInfoPopup() {
    _infoPopupFadeTimer?.cancel();
    _infoPopupHideTimer?.cancel();

    if (!_isInfoPopupMounted || !_isInfoPopupVisible) {
      setState(() {
        _isInfoPopupMounted = true;
        _isInfoPopupVisible = true;
      });
    }

    _infoPopupFadeTimer = Timer(_infoPopupVisibilityDuration, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInfoPopupVisible = false;
      });

      _infoPopupHideTimer = Timer(_infoPopupFadeDuration, () {
        if (!mounted) {
          return;
        }

        setState(() {
          _isInfoPopupMounted = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            _CameraPreviewSurface(controller: _cameraController!)
          else
            const ColoredBox(color: Colors.black),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Row(
                        children: [
                          _OverlayIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onPressed: widget.onBack,
                          ),
                          const Spacer(),
                          _OverlayIconButton(
                            icon: Icons.info_outline_rounded,
                            tooltip: 'Show frame hint',
                            onPressed: _showInfoPopup,
                          ),
                        ],
                      ),
                      if (_isInfoPopupMounted)
                        Positioned(
                          top: 0,
                          left: 64,
                          right: 64,
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              opacity: _isInfoPopupVisible ? 1 : 0,
                              duration: _infoPopupFadeDuration,
                              curve: Curves.easeOutCubic,
                              child: const _CameraInfoPopup(),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: const _ViewportCornerGuides(),
                      ),
                    ),
                  ),
                  _CameraControlStatusSlot(
                    isInitializing: _isInitializing,
                    errorMessage: _errorMessage,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _OverlayIconButton(
                        icon: _flashMode == FlashMode.off
                            ? Icons.flash_off_rounded
                            : Icons.flash_on_rounded,
                        onPressed: _toggleFlash,
                      ),
                      _ShutterButton(
                        isBusy:
                            _isInitializing || _isCapturing || _isPickingImage,
                        onPressed: _capturePhoto,
                      ),
                      _OverlayIconButton(
                        icon: Icons.photo_library_outlined,
                        onPressed: _pickFromGallery,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPreviewSurface extends StatelessWidget {
  const _CameraPreviewSurface({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    double scale = size.aspectRatio * controller.value.aspectRatio;
    if (scale < 1) {
      scale = 1 / scale;
    }

    return Transform.scale(
      scale: scale,
      child: Center(child: CameraPreview(controller)),
    );
  }
}

class _ViewportCornerGuides extends StatelessWidget {
  const _ViewportCornerGuides();

  static const double _cornerLength = 62;
  static const double _cornerRadius = 26;
  static const double _strokeWidth = 4;
  static const double _guideInset = 20;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_guideInset),
      child: CustomPaint(
        painter: _CornerGuidePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CornerGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ViewportCornerGuides._strokeWidth + 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.84)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ViewportCornerGuides._strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final List<Path> cornerPaths = <Path>[
      _topLeftPath(size),
      _topRightPath(size),
      _bottomLeftPath(size),
      _bottomRightPath(size),
    ];

    for (final Path path in cornerPaths) {
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, strokePaint);
    }
  }

  Path _topLeftPath(Size size) {
    return Path()
      ..moveTo(0, _ViewportCornerGuides._cornerLength)
      ..lineTo(0, _ViewportCornerGuides._cornerRadius)
      ..quadraticBezierTo(0, 0, _ViewportCornerGuides._cornerRadius, 0)
      ..lineTo(_ViewportCornerGuides._cornerLength, 0);
  }

  Path _topRightPath(Size size) {
    return Path()
      ..moveTo(size.width - _ViewportCornerGuides._cornerLength, 0)
      ..lineTo(size.width - _ViewportCornerGuides._cornerRadius, 0)
      ..quadraticBezierTo(
        size.width,
        0,
        size.width,
        _ViewportCornerGuides._cornerRadius,
      )
      ..lineTo(size.width, _ViewportCornerGuides._cornerLength);
  }

  Path _bottomLeftPath(Size size) {
    return Path()
      ..moveTo(0, size.height - _ViewportCornerGuides._cornerLength)
      ..lineTo(0, size.height - _ViewportCornerGuides._cornerRadius)
      ..quadraticBezierTo(
        0,
        size.height,
        _ViewportCornerGuides._cornerRadius,
        size.height,
      )
      ..lineTo(_ViewportCornerGuides._cornerLength, size.height);
  }

  Path _bottomRightPath(Size size) {
    return Path()
      ..moveTo(size.width - _ViewportCornerGuides._cornerLength, size.height)
      ..lineTo(size.width - _ViewportCornerGuides._cornerRadius, size.height)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width,
        size.height - _ViewportCornerGuides._cornerRadius,
      )
      ..lineTo(size.width, size.height - _ViewportCornerGuides._cornerLength);
  }

  @override
  bool shouldRepaint(covariant _CornerGuidePainter oldDelegate) {
    return false;
  }
}

class _CameraLoadingIndicator extends StatelessWidget {
  const _CameraLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const PulseDotsIndicator(key: ValueKey('camera-loading'));
  }
}

class _CameraControlStatus extends StatelessWidget {
  const _CameraControlStatus({
    required this.isInitializing,
    required this.errorMessage,
  });

  final bool isInitializing;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Text(
        errorMessage!,
        key: const ValueKey('camera-error'),
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white),
      );
    }

    if (!isInitializing) {
      return const SizedBox.shrink();
    }

    return const _CameraLoadingIndicator();
  }
}

class _CameraControlStatusSlot extends StatelessWidget {
  const _CameraControlStatusSlot({
    required this.isInitializing,
    required this.errorMessage,
  });

  final bool isInitializing;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (!isInitializing && errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: _CameraControlStatus(
          isInitializing: isInitializing,
          errorMessage: errorMessage,
        ),
      ),
    );
  }
}

class _CameraInfoPopup extends StatelessWidget {
  const _CameraInfoPopup();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Place the ingredients in the frame',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: IconButton(
        onPressed: onPressed,
        color: Colors.white,
        tooltip: tooltip,
        icon: Icon(icon),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.isBusy, required this.onPressed});

  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBusy ? null : onPressed,
      child: Container(
        height: 86,
        width: 86,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.84),
            width: 3,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isBusy ? Colors.white.withValues(alpha: 0.5) : Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isBusy
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.black,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
