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

   Genera `lib/firebase_options.dart` (versionado, junto con
   `ios/Runner/GoogleService-Info.plist` y `android/app/google-services.json`).
   Ver `firebase_options.example.dart` como referencia.

3. Desplegar reglas de Firestore:

   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```

4. Ejecutar:

   ```bash
   flutter run
   ```

## CI/CD (Codemagic)

Los builds de iOS corren en [Codemagic](https://codemagic.io) (la app se
compila en Mac en la nube). La configuración está versionada en
`codemagic.yaml`; al existir ese archivo, Codemagic **ignora** el workflow
configurado en su UI.

| Workflow | Trigger | Qué hace |
| --- | --- | --- |
| `ios-build-check` | push a `master` | `flutter analyze` + `flutter test` + `flutter build ios --debug --no-codesign` (valida que compile, sin firma) |
| `ios-device-dev` | manual (UI) | `flutter build ipa --release` firmado con perfil **Development** para instalar en un iPhone físico |

> **Nota SPM:** el primer paso de ambos workflows es
> `flutter config --enable-swift-package-manager` + `flutter pub get`,
> que genera `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage`
> (ignorado por git). Sin ese paso, Codemagic falla con
> `Scheme "Runner" not found from repository`.

### Probar en un iPhone físico

Requiere **Apple Developer Program** (la cuenta gratuita no sirve para
firmar en CI). Pasos en Codemagic:

1. Crear la cuenta de equipo en [developer.apple.com](https://developer.apple.com/programs/enroll/)
   y una **App Store Connect API key** (Users and Access > Integrations).
2. En Codemagic: **Team integrations > Developer Portal** → agregar la key (`.p8`, Key ID, Issuer ID).
3. Registrar el UDID de tu iPhone en
   [developer.apple.com](https://developer.apple.com/account/resources/devices/)
   (o vía **Team settings > iOS test devices** de Codemagic, que envía un
   link de registro al dispositivo).
4. Generar y subir en **Team settings > codemagic.yaml settings > Code signing identities**:
   certificado **Apple Development** + provisioning profile **Development**
   para `com.reperty.reperty` incluyendo el UDID del paso 3.
5. Ejecutar manualmente el workflow **`ios-device-dev`** y descargar el
   `.ipa` del artefacto `build/ios/ipa/*.ipa`.
6. Instalar en el iPhone (Xcode/Apple Configurator, o una herramienta de
   sideload como AltStore). El perfil de desarrollo caduca en 1 año.

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
