import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/providers/app_lock.dart';

class FakeDeviceAuth implements DeviceAuth {
  FakeDeviceAuth({this.supported = true, this.succeed = true});

  bool supported;
  bool succeed;
  int prompts = 0;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return succeed;
  }
}

ProviderContainer _container(FakeDeviceAuth auth) {
  final c = ProviderContainer(
    overrides: [deviceAuthProvider.overrideWithValue(auth)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  final t0 = DateTime(2026, 11, 17, 12);

  test('starts locked when enabled and unlocks after authentication', () async {
    final auth = FakeDeviceAuth();
    final c = _container(auth);
    final lock = c.read(appLockProvider.notifier);

    await lock.start(enabled: true);
    expect(c.read(appLockProvider), isTrue);

    expect(await lock.unlock(), isTrue);
    expect(c.read(appLockProvider), isFalse);
    expect(auth.prompts, 1);
  });

  test('failed authentication stays locked', () async {
    final c = _container(FakeDeviceAuth(succeed: false));
    final lock = c.read(appLockProvider.notifier);
    await lock.start(enabled: true);
    expect(await lock.unlock(), isFalse);
    expect(c.read(appLockProvider), isTrue);
  });

  test('never locks when disabled or without a device lock', () async {
    final c1 = _container(FakeDeviceAuth());
    await c1.read(appLockProvider.notifier).start(enabled: false);
    expect(c1.read(appLockProvider), isFalse);

    // No screen lock on the device: locking would shut the user out.
    final c2 = _container(FakeDeviceAuth(supported: false));
    await c2.read(appLockProvider.notifier).start(enabled: true);
    expect(c2.read(appLockProvider), isFalse);
  });

  test('relocks only after a while in the background', () async {
    final c = _container(FakeDeviceAuth());
    final lock = c.read(appLockProvider.notifier);
    await lock.start(enabled: true);
    await lock.unlock();

    // A share sheet or file picker: back quickly, stays unlocked.
    lock.onBackground(t0);
    await lock.onForeground(t0.add(const Duration(seconds: 10)), enabled: true);
    expect(c.read(appLockProvider), isFalse);

    lock.onBackground(t0);
    await lock.onForeground(
      t0.add(appLockGracePeriod + const Duration(seconds: 1)),
      enabled: true,
    );
    expect(c.read(appLockProvider), isTrue);
  });

  test('the auth prompt itself does not count as backgrounding', () async {
    final auth = FakeDeviceAuth();
    final c = _container(auth);
    final lock = c.read(appLockProvider.notifier);
    await lock.start(enabled: true);

    // The system PIN screen pauses the app while unlock() is running.
    final unlocking = lock.unlock();
    lock.onBackground(t0);
    await lock.onForeground(t0.add(const Duration(minutes: 5)), enabled: true);
    await unlocking;
    expect(c.read(appLockProvider), isFalse);
  });

  test('resuming after a cancelled prompt does not prompt again', () async {
    final c = _container(FakeDeviceAuth(succeed: false));
    final lock = c.read(appLockProvider.notifier);
    await lock.start(enabled: true);
    await lock.unlock();
    // The prompt closing resumes the app without a background period.
    expect(await lock.onForeground(t0, enabled: true), isFalse);
    expect(c.read(appLockProvider), isTrue);

    // After a real background period it asks once.
    lock.onBackground(t0);
    // Already locked: no new prompt either.
    expect(
      await lock.onForeground(
        t0.add(const Duration(minutes: 5)),
        enabled: true,
      ),
      isFalse,
    );
  });

  test('relocking after the grace period asks once', () async {
    final c = _container(FakeDeviceAuth());
    final lock = c.read(appLockProvider.notifier);
    await lock.start(enabled: true);
    await lock.unlock();
    lock.onBackground(t0);
    expect(
      await lock.onForeground(
        t0.add(const Duration(minutes: 1)),
        enabled: true,
      ),
      isTrue,
    );
  });
}
