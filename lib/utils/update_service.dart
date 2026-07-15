import 'dart:async' show StreamSubscription;
import 'dart:io';

import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const _staleDays = 7;
  StreamSubscription<InstallStatus>? _flexSub;

  Future<void> checkAndUpdate() async {
    if (!Platform.isAndroid) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      final stale = info.clientVersionStalenessDays ?? 0;
      if (stale >= _staleDays) {
        await InAppUpdate.performImmediateUpdate();
      } else {
        await InAppUpdate.startFlexibleUpdate();
        await _flexSub?.cancel();
        _flexSub = InAppUpdate.installUpdateListener.listen((status) {
          if (status == InstallStatus.downloaded) {
            _flexSub?.cancel();
            _flexSub = null;
            InAppUpdate.completeFlexibleUpdate().catchError((_) {});
          }
        });
      }
    } catch (_) {
      // Silently ignore: emulator, sideloaded APK, Play Store unavailable
    }
  }
}
