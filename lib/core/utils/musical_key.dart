/// Representación interna de tonalidades: 12 semitonos.
///
/// C = 0, C# = 1, D = 2, D# = 3, E = 4, F = 5,
/// F# = 6, G = 7, G# = 8, A = 9, A# = 10, B = 11.
///
/// Se aceptan bemoles como entrada (Db, Eb, Gb, Ab, Bb) y se
/// normalizan al semitono equivalente. La representación de salida
/// usa sostenidos por defecto, con opción a bemoles.
enum MusicalKey {
  c(0, 'C'),
  cSharp(1, 'C#'),
  d(2, 'D'),
  dSharp(3, 'D#'),
  e(4, 'E'),
  f(5, 'F'),
  fSharp(6, 'F#'),
  g(7, 'G'),
  gSharp(8, 'G#'),
  a(9, 'A'),
  aSharp(10, 'A#'),
  b(11, 'B');

  const MusicalKey(this.semitone, this.sharpName);

  final int semitone;
  final String sharpName;

  static const _flatNames = <int, String>{
    1: 'Db',
    3: 'Eb',
    6: 'Gb',
    8: 'Ab',
    10: 'Bb',
  };

  /// Nombre con bemoles cuando existe equivalencia, si no el de sostenidos.
  String get flatName => _flatNames[semitone] ?? sharpName;

  String display({bool useFlats = false}) =>
      useFlats ? flatName : sharpName;

  static MusicalKey fromSemitone(int semitone) =>
      MusicalKey.values.firstWhere(
        (k) => k.semitone == ((semitone % 12) + 12) % 12,
      );

  static const _aliases = <String, int>{
    'C': 0,
    'B#': 0,
    'C#': 1,
    'DB': 1,
    'D': 2,
    'D#': 3,
    'EB': 3,
    'E': 4,
    'FB': 4,
    'F': 5,
    'E#': 5,
    'F#': 6,
    'GB': 6,
    'G': 7,
    'G#': 8,
    'AB': 8,
    'A': 9,
    'A#': 10,
    'BB': 10,
    'B': 11,
    'CB': 11,
  };

  /// Parsea 'E', 'eb', 'F#', 'Gb', etc. Lanza [FormatException] si es inválido.
  static MusicalKey parse(String input) {
    final normalized = input.trim().toUpperCase().replaceAll('♯', '#').replaceAll('♭', 'B');
    final semitone = _aliases[normalized];
    if (semitone == null) {
      throw FormatException('Tonalidad inválida: $input');
    }
    return fromSemitone(semitone);
  }

  static bool isValid(String input) {
    try {
      parse(input);
      return true;
    } on FormatException {
      return false;
    }
  }

  static List<String> get allSharpNames =>
      MusicalKey.values.map((k) => k.sharpName).toList();
}

/// Utilidades de transposición. Solo se guardan original + objetivo;
/// la diferencia se calcula bajo demanda.
abstract final class KeyTransposer {
  /// Semitonos para ir de [from] a [to] (0-11).
  static int semitonesBetween(MusicalKey from, MusicalKey to) =>
      ((to.semitone - from.semitone) % 12 + 12) % 12;

  /// Transpone [key] en [offset] semitonos.
  static MusicalKey transpose(MusicalKey key, int offset) =>
      MusicalKey.fromSemitone(key.semitone + offset);

  static int semitonesBetweenNames(String from, String to) =>
      semitonesBetween(MusicalKey.parse(from), MusicalKey.parse(to));

  static String transposeName(String key, int offset) =>
      transpose(MusicalKey.parse(key), offset).sharpName;
}
