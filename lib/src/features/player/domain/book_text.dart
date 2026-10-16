import 'package:voxlivre/src/features/player/domain/timed_word.dart';

/// Le texte lu, mot à mot, avec ses pages (ADR-0010) : retrouve le mot
/// prononcé à un instant, et la phrase qui le contient.
final class BookText {
  BookText(List<TimedWord> words, List<({int page, int wordIndex})> pageStarts)
    : words = ([...words]..sort((a, b) => a.index.compareTo(b.index))),
      pageStarts = ([...pageStarts]
        ..sort((a, b) => a.wordIndex.compareTo(b.wordIndex)));

  final List<TimedWord> words;
  final List<({int page, int wordIndex})> pageStarts;

  static final _sentenceEnd = RegExp(r'[.!?…]["»”)\]]*$');

  bool get isEmpty => words.isEmpty;

  /// Position (dans [words]) du mot prononcé à [ms] : le dernier qui a
  /// commencé ; `-1` avant le premier.
  int positionAt(int ms) {
    var low = 0;
    var high = words.length - 1;
    var found = -1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (words[mid].startMs <= ms) {
        found = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return found;
  }

  /// Position (dans [words]) du mot d'index global [wordIndex], ou du plus
  /// proche qui suit ; `-1` si aucun.
  int positionOfWord(int wordIndex) {
    var low = 0;
    var high = words.length - 1;
    var found = -1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (words[mid].index >= wordIndex) {
        found = mid;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    return found;
  }

  /// Bornes (positions incluses) de la phrase qui contient [position].
  ({int start, int end}) sentenceAround(int position) {
    var start = position;
    while (start > 0 && !_sentenceEnd.hasMatch(words[start - 1].text)) {
      start--;
    }
    var end = position;
    while (end < words.length - 1 && !_sentenceEnd.hasMatch(words[end].text)) {
      end++;
    }
    return (start: start, end: end);
  }

  /// Page du mot à [position] (1 si le manifeste n'en donne pas).
  int pageOf(int position) {
    if (position < 0 || words.isEmpty) return pageStarts.firstOrNull?.page ?? 1;
    final index = words[position].index;
    var page = pageStarts.firstOrNull?.page ?? 1;
    for (final start in pageStarts) {
      if (start.wordIndex > index) break;
      page = start.page;
    }
    return page;
  }

  /// Les mots regroupés par page, dans l'ordre : (page, première position,
  /// dernière position incluse).
  List<({int page, int from, int to})> get pages {
    if (words.isEmpty) return const [];
    final result = <({int page, int from, int to})>[];
    var currentPage = pageOf(0);
    var from = 0;
    for (var i = 1; i < words.length; i++) {
      final page = pageOf(i);
      if (page != currentPage) {
        result.add((page: currentPage, from: from, to: i - 1));
        currentPage = page;
        from = i;
      }
    }
    result.add((page: currentPage, from: from, to: words.length - 1));
    return result;
  }
}
