// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subs_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subsStorage)
final subsStorageProvider = SubsStorageProvider._();

final class SubsStorageProvider
    extends
        $FunctionalProvider<
          AsyncValue<Storage<String, String>>,
          Storage<String, String>,
          FutureOr<Storage<String, String>>
        >
    with
        $FutureModifier<Storage<String, String>>,
        $FutureProvider<Storage<String, String>> {
  SubsStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subsStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subsStorageHash();

  @$internal
  @override
  $FutureProviderElement<Storage<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Storage<String, String>> create(Ref ref) {
    return subsStorage(ref);
  }
}

String _$subsStorageHash() => r'4acc4ca046a5620b36fbf0217848c11a36b370fc';

@ProviderFor(SubsController)
@JsonPersist()
final subsControllerProvider = SubsControllerProvider._();

@JsonPersist()
final class SubsControllerProvider
    extends $AsyncNotifierProvider<SubsController, List<SubSlice>> {
  SubsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subsControllerHash();

  @$internal
  @override
  SubsController create() => SubsController();
}

String _$subsControllerHash() => r'ceab2e29cd1aede851dc24a4433477299869a73a';

@JsonPersist()
abstract class _$SubsControllerBase extends $AsyncNotifier<List<SubSlice>> {
  FutureOr<List<SubSlice>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<SubSlice>>, List<SubSlice>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SubSlice>>, List<SubSlice>>,
              AsyncValue<List<SubSlice>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

// **************************************************************************
// JsonGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
abstract class _$SubsController extends _$SubsControllerBase {
  /// The default key used by [persist].
  String get key {
    const resolvedKey = "SubsController";
    return resolvedKey;
  }

  /// A variant of [persist], for JSON-specific encoding.
  ///
  /// You can override [key] to customize the key used for storage.
  PersistResult persist(
    FutureOr<Storage<String, String>> storage, {
    String? key,
    String Function(List<SubSlice> state)? encode,
    List<SubSlice> Function(String encoded)? decode,
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
            return (e as List)
                .map((e) => SubSlice.fromJson(e as Map<String, Object?>))
                .toList();
          },
      options: options,
    );
  }
}
