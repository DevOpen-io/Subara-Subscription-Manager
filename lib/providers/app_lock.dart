import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_lock.g.dart';

/// Device authentication (biometrics or the screen lock PIN/pattern).
abstract class DeviceAuth {
  /// Whether the device has any screen lock to authenticate with.
  Future<bool> isSupported();

  Future<bool> authenticate(String reason);
}

class LocalDeviceAuth implements DeviceAuth {
  final _auth = LocalAuthentication();

  @override
  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('Device auth check failed: $e');
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      // Falls back to the device PIN/pattern, so losing biometrics can't
      // lock the user out.
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('Device auth failed: $e');
      return false;
    }
  }
}

@Riverpod(keepAlive: true)
DeviceAuth deviceAuth(Ref ref) => LocalDeviceAuth();

/// How long the app may be in the background (share sheet, file picker)
/// before it locks again.
const appLockGracePeriod = Duration(seconds: 30);

/// Whether the app is currently locked.
@Riverpod(keepAlive: true)
class AppLock extends _$AppLock {
  DateTime? _backgroundSince;
  bool _authenticating = false;

  @override
  bool build() => false;

  /// Locks at app start when enabled. Never locks a device without a screen
  /// lock, which would shut the user out.
  Future<void> start({required bool enabled}) async {
    state = enabled && await ref.read(deviceAuthProvider).isSupported();
  }

  void onBackground(DateTime now) {
    // The system auth screen itself pauses the app.
    if (_authenticating) return;
    _backgroundSince ??= now;
  }

  /// Returns true only when this call locked the app, so the caller asks
  /// for authentication once. Closing the auth prompt (cancelled) also
  /// "resumes" the app; that must not reopen the prompt in a loop.
  Future<bool> onForeground(DateTime now, {required bool enabled}) async {
    final since = _backgroundSince;
    _backgroundSince = null;
    if (_authenticating || since == null || !enabled || state) return false;
    if (now.difference(since) < appLockGracePeriod) return false;
    await start(enabled: true);
    return state;
  }

  /// Asks for authentication; unlocks on success.
  Future<bool> unlock({String reason = ''}) async {
    if (_authenticating) return false;
    _authenticating = true;
    try {
      final ok = await ref.read(deviceAuthProvider).authenticate(reason);
      if (ok) state = false;
      return ok;
    } finally {
      _authenticating = false;
      _backgroundSince = null;
    }
  }

  /// Authenticates without changing the lock (to turn the lock on or off).
  Future<bool> confirm({String reason = ''}) async {
    final auth = ref.read(deviceAuthProvider);
    if (!await auth.isSupported()) return false;
    _authenticating = true;
    try {
      return await auth.authenticate(reason);
    } finally {
      _authenticating = false;
      _backgroundSince = null;
    }
  }
}
