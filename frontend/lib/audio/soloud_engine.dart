import 'package:flutter_soloud/flutter_soloud.dart';

Future<void>? _initialization;

Future<void> ensureSoloudInitialized() async {
  final soloud = SoLoud.instance;
  if (soloud.isInitialized) return;

  final pending = _initialization;
  if (pending != null) return pending;

  final initialization = soloud.init();
  _initialization = initialization;
  try {
    await initialization;
  } finally {
    _initialization = null;
  }
}
