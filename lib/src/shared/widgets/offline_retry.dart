import 'dart:async';

import 'package:flutter/widgets.dart';

/// Délai entre deux essais tant que l'écran est hors ligne.
const offlineRetryEvery = Duration(seconds: 30);

/// Le code d'un échec faute de réseau.
bool isOfflineCode(String? code) =>
    code == 'NETWORK_UNAVAILABLE' || code == 'TIMEOUT';

/// Tant que [offline] : réessaie au retour sur l'écran (une page posée
/// dessus se ferme), au retour de l'app au premier plan, et toutes les
/// [every] quand l'écran est visible. Un essai sans réseau échoue en moins
/// d'une seconde : le bandeau « Hors ligne » part seul au retour du réseau.
class OfflineRetry extends StatefulWidget {
  const OfflineRetry({
    required this.offline,
    required this.onRetry,
    required this.child,
    this.every = offlineRetryEvery,
    super.key,
  });

  final bool offline;
  final Future<void> Function() onRetry;
  final Widget child;
  final Duration every;

  @override
  State<OfflineRetry> createState() => _OfflineRetryState();
}

class _OfflineRetryState extends State<OfflineRetry> {
  Timer? _timer;
  late final AppLifecycleListener _lifecycle;

  /// Écran visible (une page couvrante coupe `TickerMode` dessous).
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _retry);
    _timer = Timer.periodic(widget.every, (_) => _retry());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.of(context);
    final back = visible && !_visible;
    _visible = visible;
    if (back) _retry();
  }

  void _retry() {
    if (mounted && widget.offline && _visible) unawaited(widget.onRetry());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
