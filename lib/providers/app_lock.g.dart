// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lock.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deviceAuth)
final deviceAuthProvider = DeviceAuthProvider._();

final class DeviceAuthProvider
    extends $FunctionalProvider<DeviceAuth, DeviceAuth, DeviceAuth>
    with $Provider<DeviceAuth> {
  DeviceAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceAuthHash();

  @$internal
  @override
  $ProviderElement<DeviceAuth> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeviceAuth create(Ref ref) {
    return deviceAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceAuth>(value),
    );
  }
}

String _$deviceAuthHash() => r'9e5857d434ce5f0c24de717c13f182385c306499';

/// Whether the app is currently locked.

@ProviderFor(AppLock)
final appLockProvider = AppLockProvider._();

/// Whether the app is currently locked.
final class AppLockProvider extends $NotifierProvider<AppLock, bool> {
  /// Whether the app is currently locked.
  AppLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockHash();

  @$internal
  @override
  AppLock create() => AppLock();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$appLockHash() => r'70279ebc2271c847df71662a5f6bdb81d07fe735';

/// Whether the app is currently locked.

abstract class _$AppLock extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
