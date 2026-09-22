import 'dart:math';

import '../constants/app_constants.dart';

/// Genera códigos cortos de grupo (p. ej. AB72K) aptos para dictar en voz alta.
/// Se excluyen caracteres ambiguos (I, L, O, 0, 1).
abstract final class CodeGenerator {
  static final _random = Random.secure();

  static String groupCode() {
    const alphabet = AppConstants.groupCodeAlphabet;
    return List.generate(
      AppConstants.groupCodeLength,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }
}
