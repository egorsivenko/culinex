import 'dart:async';

import 'package:flutter/services.dart';

class AppHaptics {
  const AppHaptics._();

  static bool _isEnabled = true;

  static bool get isEnabled => _isEnabled;

  static void setEnabled(bool isEnabled) {
    _isEnabled = isEnabled;
  }

  static void selection() => _run(HapticFeedback.selectionClick);

  static void tap() => _run(HapticFeedback.lightImpact);

  static void commit() => _run(HapticFeedback.mediumImpact);

  static void destructive() => _run(HapticFeedback.heavyImpact);

  static void _run(Future<void> Function() feedback) {
    if (!_isEnabled) {
      return;
    }

    unawaited(feedback().catchError((Object _) {}));
  }
}
