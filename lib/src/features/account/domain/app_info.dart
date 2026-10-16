/// Ce que l'app sait d'elle-même (version de l'APK).
abstract interface class AppInfo {
  /// « 0.1.0 (1) ».
  Future<String> version();
}
