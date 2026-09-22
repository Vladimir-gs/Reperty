import 'musical_key.dart';

abstract final class Validators {
  static String? required(String? value, [String message = 'Campo requerido']) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo requerido';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(value.trim())) return 'Email inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Campo requerido';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  static String? musicalKey(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo requerido';
    if (!MusicalKey.isValid(value)) return 'Tono inválido (ej. E, Bb, F#)';
    return null;
  }
}
