abstract final class Validator {
  static String? required(String? value, {String fieldName = 'Trường này'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName là bắt buộc';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final isValid = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(value.trim());
    return isValid ? null : 'Email không hợp lệ';
  }

  static String? maxLength(String? value, int maximum) {
    if (value != null && value.length > maximum) {
      return 'Không được vượt quá $maximum ký tự';
    }
    return null;
  }
}
