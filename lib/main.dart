import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/messaging_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart' as opts;
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: opts.DefaultFirebaseOptions.currentPlatform,
  );

  // Persistencia offline-first.
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  } on Exception catch (_) {
    // Settings solo puede configurarse una vez; ignorar en hot restart.
  }

  if (!kDebugMode) {
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  runApp(const ProviderScope(child: RepertyApp()));
}

class RepertyApp extends ConsumerWidget {
  const RepertyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Inicializa FCM (permiso + token) sin bloquear la UI.
    ref.watch(messagingServiceProvider).init().ignore();

    return MaterialApp.router(
      title: 'Reperty',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

extension _Ignore on Future<void> {
  void ignore() {}
}
