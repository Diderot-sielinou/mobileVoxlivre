import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/account/application/read_app_version.dart';
import 'package:voxlivre/src/features/account/domain/app_info.dart';
import 'package:voxlivre/src/features/account/infrastructure/package_app_info.dart';

/// Composition du compte (ADR-0002, ADR-0014).

final appInfoProvider = Provider<AppInfo>((ref) => const PackageAppInfo());

final readAppVersionProvider = Provider<ReadAppVersion>(
  (ref) => ReadAppVersion(ref.watch(appInfoProvider)),
);
