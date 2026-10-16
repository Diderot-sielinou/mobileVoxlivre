import 'package:package_info_plus/package_info_plus.dart';
import 'package:voxlivre/src/features/account/domain/app_info.dart';

/// [AppInfo] lu dans l'APK (`package_info_plus`).
final class PackageAppInfo implements AppInfo {
  const PackageAppInfo();

  @override
  Future<String> version() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
}
