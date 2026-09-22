# Reperty

Repertorio musical compartido para músicos, grupos, coros y ministerios de alabanza.

MVP multiplataforma (Android + iOS) con **Flutter + Firebase**, diseño **offline-first**.

## Stack

- Flutter + Dart + Material 3
- Estado: Riverpod
- Navegación: GoRouter
- Backend: Firebase Auth, Cloud Firestore (persistencia offline), FCM, Crashlytics

## Requisitos

- Flutter SDK estable (>= 3.24)
- Cuenta de Firebase + proyecto creado
- Android SDK / Xcode según plataforma

## Puesta en marcha

1. Instalar dependencias:

   ```bash
   flutter pub get
   ```

2. Configurar Firebase (una sola vez):

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Esto genera `lib/firebase_options.dart` (ignorado por git, ver `firebase_options.example.dart`).

3. Desplegar reglas de Firestore:

   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```

4. Ejecutar:

   ```bash
   flutter run
   ```

## Estructura

```text
lib/
├── core/        # constants, theme, utils (tonalidades), services
├── features/    # auth, groups, songs, setlists, profile
├── routing/     # GoRouter
├── shared/      # widgets y providers compartidos
└── main.dart
```

## Offline-first

Firestore tiene persistencia offline activada (`persistenceEnabled: true`).
Toda lectura/escritura va contra caché local primero; Firebase sincroniza
automáticamente al volver la conexión. No hay SQLite/Drift en el MVP.

## Modelo Firestore

```text
users/{uid}
groups/{groupId}
groups/{groupId}/members/{userId}
songs/{songId}                              # catálogo canónico global
groups/{groupId}/songs/{songId}             # repertorio del grupo (denormalizado)
groups/{groupId}/songs/{songId}/keys/{userId}  # tono por vocalista
groups/{groupId}/setlists/{setlistId}
groups/{groupId}/setlists/{setlistId}/items/{itemId}
```

Ver `firestore.rules` y `docs/modelo-datos.md` (cuando exista) para detalles.
