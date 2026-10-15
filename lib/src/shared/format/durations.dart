/// Formats d'affichage des durées et des dates, en français.
abstract final class VoxFormat {
  /// Durée d'écoute : « 42 min », « 1 h 14 », « moins d'une minute ».
  static String listening(Duration d) {
    final minutes = (d.inSeconds / 60).round();
    if (minutes < 1) return 'moins d’une minute';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0
        ? '$hours h'
        : '$hours h ${rest.toString().padLeft(2, '0')}';
  }

  /// Nombre à la française : « 214 300 » (espace fine insécable).
  static String count(int value) {
    final digits = value.abs().toString();
    final groups = <String>[];
    for (var end = digits.length; end > 0; end -= 3) {
      groups.insert(0, digits.substring(end < 3 ? 0 : end - 3, end));
    }
    return '${value < 0 ? '-' : ''}${groups.join('\u202F')}';
  }

  /// Nombre de pages : « 1 page », « 84 pages ».
  static String pages(int count) => count > 1 ? '$count pages' : '$count page';

  /// Ancienneté : « à l'instant », « il y a 5 min », « il y a 2 h »,
  /// « hier », « il y a 3 jours ».
  static String ago(DateTime then, DateTime now) {
    final d = now.difference(then);
    if (d.inMinutes < 1) return 'à l’instant';
    if (d.inHours < 1) return 'il y a ${d.inMinutes} min';
    if (d.inDays < 1) return 'il y a ${d.inHours} h';
    if (d.inDays == 1) return 'hier';
    return 'il y a ${d.inDays} jours';
  }
}
