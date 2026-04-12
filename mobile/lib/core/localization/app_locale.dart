import 'package:flutter/widgets.dart';

abstract final class AppLocale {
  static const Locale english = Locale('en');
  static const Locale ukrainian = Locale('uk');
  static const List<Locale> supportedLocales = <Locale>[english, ukrainian];

  static Locale normalize(Locale locale) {
    return switch (locale.languageCode) {
      'uk' => ukrainian,
      _ => english,
    };
  }

  static bool isUkrainian(Locale locale) => normalize(locale) == ukrainian;
}
