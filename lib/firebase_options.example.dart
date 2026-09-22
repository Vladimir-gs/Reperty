// Archivo de ejemplo. Generar el real con `flutterfire configure`.
// NO commitear el archivo real (ver .gitignore).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Reemplazar con la salida de flutterfire_cli.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Falta lib/firebase_options.dart. Ejecutar `flutterfire configure`.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REEMPLAZAR',
    appId: 'REEMPLAZAR',
    messagingSenderId: 'REEMPLAZAR',
    projectId: 'REEMPLAZAR',
    storageBucket: 'REEMPLAZAR',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REEMPLAZAR',
    appId: 'REEMPLAZAR',
    messagingSenderId: 'REEMPLAZAR',
    projectId: 'REEMPLAZAR',
    storageBucket: 'REEMPLAZAR',
    iosBundleId: 'com.reperty.app',
  );

  // ignore: unused_element
  static void _touch(TargetPlatform _) => defaultTargetPlatform;
}
