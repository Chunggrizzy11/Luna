import 'package:flutter/material.dart';

/// Friendly Design System - Radius Tokens
/// Based on: E:/DesignSkillAI/friendly/radius.md

abstract final class AppRadius {
  // ============================================
  // RADIUS TOKENS
  // ============================================

  static const Radius r6 = Radius.circular(6);
  static const Radius r8 = Radius.circular(8);
  static const Radius r12 = Radius.circular(12);
  static const Radius r24 = Radius.circular(24);
  static const Radius r48 = Radius.circular(48);
  static const Radius rPill = Radius.circular(9999);

  // ============================================
  // COMPONENT MAPPING
  // ============================================

  static const BorderRadius controls = BorderRadius.all(r6);
  static const BorderRadius card = BorderRadius.all(r48);
  static const BorderRadius modal = BorderRadius.all(r24);
  static const BorderRadius pill = BorderRadius.all(rPill);
}
