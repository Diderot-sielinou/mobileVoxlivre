import 'package:voxlivre/src/features/player/domain/timed_word.dart';

/// Lit le WebVTT d'une partie (un repère par mot, ADR-0011 du backend) ;
/// [offsetMs] (début de la partie) rend les instants absolus. Un repère
/// mal formé est ignoré, pas toute la partie.
List<TimedWord> parseWebVtt(String text, {required int offsetMs}) {
  final words = <TimedWord>[];
  final blocks = text.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'));
  for (final block in blocks) {
    final lines = block.trim().split('\n');
    if (lines.length < 3) continue;
    final index = int.tryParse(lines[0].trim());
    final timing = _timing.firstMatch(lines[1]);
    if (index == null || timing == null) continue;
    words.add(
      TimedWord(
        index: index,
        text: _unescape(lines.sublist(2).join(' ').trim()),
        startMs: offsetMs + _ms(timing, 1),
        endMs: offsetMs + _ms(timing, 5),
      ),
    );
  }
  return words;
}

final _timing = RegExp(
  r'(\d+):(\d{2}):(\d{2})\.(\d{3})\s+-->\s+(\d+):(\d{2}):(\d{2})\.(\d{3})',
);

int _ms(RegExpMatch m, int from) =>
    int.parse(m[from]!) * 3600000 +
    int.parse(m[from + 1]!) * 60000 +
    int.parse(m[from + 2]!) * 1000 +
    int.parse(m[from + 3]!);

String _unescape(String text) => text
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');
