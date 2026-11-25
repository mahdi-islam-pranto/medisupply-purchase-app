/// Form checks shared by the sign-in and change-PIN forms.
/// Each returns an error message, or `null` when the value is fine.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Phone number (any spaces/dashes) or email address.
  static String? phoneOrEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your phone number or email';
    if (v.contains('@')) {
      return _email.hasMatch(v) ? null : 'Enter a valid email address';
    }
    if (!RegExp(r'^[+\d\s\-()]+$').hasMatch(v)) {
      return 'Enter a valid phone number or email';
    }
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 14) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? required(String? value, String message) =>
      (value == null || value.isEmpty) ? message : null;

  /// New PIN rule from the API: at least 6 characters.
  static String? newPin(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a new PIN';
    if (v.length < 6) return 'PIN must be at least 6 characters';
    return null;
  }
}
