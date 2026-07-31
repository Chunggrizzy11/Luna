import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  static const small = Radius.circular(8);
  static const medium = Radius.circular(12);
  static const large = Radius.circular(20);

  static const card = BorderRadius.all(medium);
  static const dialog = BorderRadius.all(large);
  static const pill = BorderRadius.all(Radius.circular(999));
}
