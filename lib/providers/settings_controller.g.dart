// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(settingsStorage)
final settingsStorageProvider = SettingsStorageProvider._();

final class SettingsStorageProvider
    extends
        $FunctionalProvider<
          AsyncValue<JsonSqFliteStorage>,
          JsonSqFliteStorage,
          FutureOr<JsonSqFliteStorage>
        >
    with
        $FutureModifier<JsonSqFliteStorage>,
        $FutureProvider<JsonSqFliteStorage> {
  SettingsStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsStorageHash();

  @$internal
  @override
  $FutureProviderElement<JsonSqFliteStorage> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<JsonSqFliteStorage> create(Ref ref) {
    return settingsStorage(ref);
  }
}

String _$settingsStorageHash() => r'a3a38c976342a6e31db1075c1f8fad90f4a5eb0a';

@ProviderFor(SettingsController)
@JsonPersist()
final settingsControllerProvider = SettingsControllerProvider._();

@JsonPersist()
final class SettingsControllerProvider
    extends $AsyncNotifierProvider<SettingsController, SettingsViewModel> {
  SettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsControllerHash();

  @$internal
  @override
  SettingsController create() => SettingsController();
}

String _$settingsControllerHash() =>
    r'125557f6cd8d5047c503eaff774a4a994d570f92';

@JsonPersist()
abstract class _$SettingsControllerBase
    extends $AsyncNotifier<SettingsViewModel> {
  FutureOr<SettingsViewModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SettingsViewModel>, SettingsViewModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SettingsViewModel>, SettingsViewModel>,
              AsyncValue<SettingsViewModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

// **************************************************************************
// JsonGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
abstract class _$SettingsController extends _$SettingsControllerBase {
  /// The default key used by [persist].
  String get key {
    const resolvedKey = "SettingsController";
    return resolvedKey;
  }

  /// A variant of [persist], for JSON-specific encoding.
  ///
  /// You can override [key] to customize the key used for storage.
  PersistResult persist(
    FutureOr<Storage<String, String>> storage, {
    String? key,
    String Function(SettingsViewModel state)? encode,
    SettingsViewModel Function(String encoded)? decode,
    StorageOptions options = const StorageOptions(),
  }) {
    return NotifierPersistX(this).persist<String, String>(
      storage,
      key: key ?? this.key,
      encode: encode ?? $jsonCodex.encode,
      decode:
          decode ??
          (encoded) {
            final e = $jsonCodex.decode(encoded);
            return SettingsViewModel.fromJson(e as Map<String, Object?>);
          },
      options: options,
    );
  }
}
