import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/core/clock.dart';

/// Horloge de l'app ; les tests la remplacent par une horloge fixe.
final clockProvider = Provider<Clock>((ref) => const SystemClock());
