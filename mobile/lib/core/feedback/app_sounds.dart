import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AppSounds {
  const AppSounds._();

  static const double _clickVolume = 0.65;
  static const String _clickAssetPath = 'sounds/click.mp3';

  static bool _isEnabled = true;
  static Future<AudioPool>? _clickPool;

  static bool get isEnabled => _isEnabled;

  static void setEnabled(bool isEnabled) {
    _isEnabled = isEnabled;
  }

  static void click() => _run(_playClick);

  static Future<void> dispose() async {
    final Future<AudioPool>? clickPool = _clickPool;
    _clickPool = null;
    if (clickPool == null) {
      return;
    }

    try {
      await (await clickPool).dispose();
    } catch (_) {
      // Ignore platform/audio-cache failures during app shutdown or tests.
    }
  }

  static void _run(Future<void> Function() sound) {
    if (!_isEnabled) {
      return;
    }

    unawaited(sound().catchError((Object _) {}));
  }

  static Future<void> _playClick() async {
    final AudioPool pool = await (_clickPool ??= AudioPool.createFromAsset(
      path: _clickAssetPath,
      minPlayers: 2,
      maxPlayers: 5,
    ));
    await pool.start(volume: _clickVolume);
  }
}
