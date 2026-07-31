import 'package:flutter/material.dart';

abstract final class AppTextStyle {
  static const display = TextStyle(
    fontSize: 32,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );
  static const title = TextStyle(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const body = TextStyle(fontSize: 16, height: 1.5);
  static const label = TextStyle(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
}
