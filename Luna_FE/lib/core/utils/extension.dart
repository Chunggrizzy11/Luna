import 'package:flutter/material.dart';

extension NullableTrimmedString on String? {
  String? get trimmedOrNull {
    final trimmed = this?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
}
