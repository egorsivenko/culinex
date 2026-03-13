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
  CameraController? _cameraController;
  CameraDescription? _selectedCamera;
  List<CameraDescription> _availableCameras = const [];
  FlashMode _flashMode = FlashMode.off;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isPickingImage = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
                  Row(
                    children: [
                      _OverlayIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: widget.onBack,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Place the ingredients in the frame',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Keep the products separated and well lit for the cleanest scan.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  IgnorePointer(
                    child: Container(
                      height: 280,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 120,
                          height: 6,
                          margin: const EdgeInsets.only(top: 18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.36),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _buildStatusLine(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
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

  Widget _buildStatusLine(BuildContext context) {
    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        key: const ValueKey('camera-error'),
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white),
      );
    }

    if (_isInitializing) {
      return const PulseDotsIndicator(key: ValueKey('camera-loading'));
    }

    return Text(
      'Tap the shutter when the whole ingredient spread is visible.',
      key: const ValueKey('camera-ready'),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.white.withValues(alpha: 0.76),
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

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

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
