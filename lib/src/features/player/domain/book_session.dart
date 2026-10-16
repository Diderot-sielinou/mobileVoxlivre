import 'package:voxlivre/src/features/player/domain/book_text.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';
import 'package:voxlivre/src/features/player/domain/timed_word.dart';

/// Parties chargées : leur audio et leurs mots.
final class LoadedParts {
  const LoadedParts({required this.audio, required this.words});

  final List<AudioPart> audio;
  final List<TimedWord> words;
}

/// Un livre ouvert : manifeste, texte, parties, position de reprise.
final class BookSession {
  const BookSession({
    required this.manifest,
    required this.text,
    required this.parts,
    this.resumeAt,
  });

  final Manifest manifest;
  final BookText text;
  final List<AudioPart> parts;

  /// Où reprendre (la plus récente des positions locale et serveur).
  final ReadingPosition? resumeAt;
}
