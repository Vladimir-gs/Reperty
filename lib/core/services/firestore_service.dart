import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Instancia de Firestore con persistencia offline activada (offline-first).
///
/// Toda la app consume este provider; las pantallas nunca configuran
/// Firestore por su cuenta.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  final db = FirebaseFirestore.instance;
  db.settings = const Settings(persistenceEnabled: true);
  return db;
});
