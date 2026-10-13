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
