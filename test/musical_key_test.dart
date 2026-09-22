import 'package:flutter_test/flutter_test.dart';
import 'package:reperty/core/utils/code_generator.dart';
import 'package:reperty/core/utils/musical_key.dart';

void main() {
  group('MusicalKey.parse', () {
    test('acepta sostenidos', () {
      expect(MusicalKey.parse('C#').semitone, 1);
      expect(MusicalKey.parse('F#').semitone, 6);
    });

    test('acepta bemoles como equivalencia', () {
      expect(MusicalKey.parse('Db').semitone, 1);
      expect(MusicalKey.parse('Eb').semitone, 3);
      expect(MusicalKey.parse('Bb').semitone, 10);
      expect(MusicalKey.parse('Gb').semitone, 6);
      expect(MusicalKey.parse('Ab').semitone, 8);
    });

    test('es insensible a mayúsculas y espacios', () {
      expect(MusicalKey.parse('  eb ').semitone, 3);
    });

    test('rechaza entradas inválidas', () {
      expect(() => MusicalKey.parse('H'), throwsFormatException);
      expect(MusicalKey.isValid('H'), isFalse);
      expect(MusicalKey.isValid('G'), isTrue);
    });
  });

  group('KeyTransposer', () {
    test('Hosanna: E original -> F vocalista = +1 semitono', () {
      expect(KeyTransposer.semitonesBetweenNames('E', 'F'), 1);
    });

    test('C -> E = +4 semitonos', () {
      expect(KeyTransposer.semitonesBetweenNames('C', 'E'), 4);
    });

    test('transpone correctamente con enarmónicos', () {
      expect(KeyTransposer.transposeName('C', 1), 'C#');
      expect(KeyTransposer.transposeName('B', 1), 'C');
      expect(KeyTransposer.transposeName('E', 1), 'F');
    });

    test('representación en bemoles', () {
      expect(MusicalKey.parse('Db').display(useFlats: true), 'Db');
      expect(MusicalKey.e.display(useFlats: true), 'E');
    });
  });

  group('CodeGenerator', () {
    test('genera códigos de 5 caracteres sin ambiguos', () {
      for (var i = 0; i < 50; i++) {
        final code = CodeGenerator.groupCode();
        expect(code.length, 5);
        expect(code, isNot(contains('I')));
        expect(code, isNot(contains('O')));
        expect(code, isNot(contains('0')));
        expect(code, isNot(contains('1')));
      }
    });
  });
}
