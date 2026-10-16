import 'package:voxlivre/src/features/account/domain/app_info.dart';

/// La version affichée en bas du Profil.
final class ReadAppVersion {
  const ReadAppVersion(this._info);

  final AppInfo _info;

  Future<String> call() => _info.version();
}
