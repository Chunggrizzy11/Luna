abstract final class Helper {
  static int clampInt(int value, {required int min, required int max}) {
    if (min > max) throw ArgumentError('min must not exceed max');
    return value.clamp(min, max);
  }

  static bool hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
