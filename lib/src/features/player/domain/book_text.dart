import 'package:voxlivre/src/features/player/domain/bookmark.dart';
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

  /// Index global du premier mot de [page], ou `null` si inconnue.
  int? _pageStart(int page) {
    for (final start in pageStarts) {
      if (start.page == page) return start.wordIndex;
    }
    return null;
  }

  /// Ancrage d'un marque-page sur le mot à [position] : page et index du
  /// mot dans la page (ADR-0012).
  ({int page, int wordIndex}) anchorOf(int position) {
    final page = pageOf(position);
    final start = _pageStart(page) ?? 0;
    return (page: page, wordIndex: words[position].index - start);
  }

  /// Position (dans [words]) du mot ancré à ([page], [wordIndex]) ; `-1` si
  /// sa partie n'est pas chargée (aperçu) ou la page inconnue.
  int positionOfAnchor(int page, int wordIndex) {
    final start = _pageStart(page);
    if (start == null) return -1;
    final position = positionOfWord(start + wordIndex);
    return position >= 0 && words[position].index == start + wordIndex
        ? position
        : -1;
  }

  /// Quelques mots à partir de [position] (extrait d'un marque-page).
  String excerptAt(int position, {int count = bookmarkExcerptWords}) => [
    for (var i = position; i < words.length && i < position + count; i++)
      words[i].text,
  ].join(' ');

  /// Instant où finit la page du mot à [position] : début du premier mot
  /// de la page suivante, sinon fin du dernier mot chargé (minuterie « fin
  /// de la page »).
  int pageEndMs(int position) {
    if (words.isEmpty) return 0;
    final page = pageOf(position < 0 ? 0 : position);
    final sorted = pageStarts;
    final at = sorted.indexWhere((s) => s.page == page);
    if (at >= 0 && at + 1 < sorted.length) {
      final next = positionOfWord(sorted[at + 1].wordIndex);
      if (next >= 0) return words[next].startMs;
    }
    return words.last.endMs;
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
