import 'package:voxlivre/src/core/failure.dart';

/// Note d'un marque-page : 2 000 caractères au plus (ADR-0028 du backend).
const bookmarkNoteMax = 2000;

/// Marque-pages d'un document : 500 au plus (ADR-0028 du backend).
const bookmarksPerDocumentMax = 500;

/// Mots de l'extrait, à partir de l'ancrage.
const bookmarkExcerptWords = 6;

/// Un marque-page (ADR-0012) : ancré au texte du document (page, mot dans
/// la page), jamais à une conversion.
final class Bookmark {
  const Bookmark({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.wordIndex,
    required this.excerpt,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.needsReview = false,
    this.deletedAt,
    this.pending = false,
  });

  /// UUID créé sur l'appareil.
  final String id;
  final String documentId;
  final int pageNumber;

  /// Index du mot dans la page (0 = premier).
  final int wordIndex;
  final String excerpt;
  final String note;

  /// Texte modifié depuis : replacé au mot le plus proche, à vérifier.
  final bool needsReview;
  final DateTime createdAt;

  /// Instant de la dernière modification sur l'appareil : départage.
  final DateTime updatedAt;

  /// Supprimé (trace gardée jusqu'à l'envoi).
  final DateTime? deletedAt;

  /// Pas encore reçu par le serveur.
  final bool pending;

  bool get hasNote => note.trim().isNotEmpty;

  bool get deleted => deletedAt != null;

  Bookmark copyWith({
    int? pageNumber,
    int? wordIndex,
    String? excerpt,
    String? note,
    bool? needsReview,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? pending,
  }) => Bookmark(
    id: id,
    documentId: documentId,
    pageNumber: pageNumber ?? this.pageNumber,
    wordIndex: wordIndex ?? this.wordIndex,
    excerpt: excerpt ?? this.excerpt,
    note: note ?? this.note,
    needsReview: needsReview ?? this.needsReview,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    pending: pending ?? this.pending,
  );
}

/// Le serveur refuse ce marque-page pour de bon (400, 404, 409, 422) :
/// inutile de le renvoyer (ADR-0012). Le code du backend reste lisible.
final class BookmarkRejected extends Failure {
  const BookmarkRejected(super.code);
}
