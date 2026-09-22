import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Arquitectura lista para FCM. El MVP no muestra notificaciones,
/// pero el servicio deja el permiso + token resueltos.
final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService(FirebaseMessaging.instance);
});

class MessagingService {
  MessagingService(this._messaging);

  final FirebaseMessaging _messaging;

  Future<void> init() async {
    await _messaging.requestPermission();
    // Token disponible para guardar en users/{uid} cuando se necesite.
    await _messaging.getToken();
    FirebaseMessaging.onMessage.listen((_) {});
  }
}
