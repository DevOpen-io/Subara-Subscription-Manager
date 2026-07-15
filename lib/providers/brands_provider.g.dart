// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brands_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(brandsStorage)
final brandsStorageProvider = BrandsStorageProvider._();

final class BrandsStorageProvider
    extends
        $FunctionalProvider<
          AsyncValue<JsonSqFliteStorage>,
          JsonSqFliteStorage,
          FutureOr<JsonSqFliteStorage>
        >
    with
        $FutureModifier<JsonSqFliteStorage>,
        $FutureProvider<JsonSqFliteStorage> {
  BrandsStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'brandsStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$brandsStorageHash();

  @$internal
  @override
  $FutureProviderElement<JsonSqFliteStorage> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<JsonSqFliteStorage> create(Ref ref) {
    return brandsStorage(ref);
  }
}

String _$brandsStorageHash() => r'e6c82756df3f3111599fba738a880ba51c90b461';

@ProviderFor(Brands)
@JsonPersist()
final brandsProvider = BrandsProvider._();

@JsonPersist()
final class BrandsProvider extends $AsyncNotifierProvider<Brands, List<Brand>> {
  BrandsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'brandsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$brandsHash();

  @$internal
  @override
  Brands create() => Brands();
}

String _$brandsHash() => r'7e2ef10206303a9c80e491878ab37959549b938e';

@JsonPersist()
abstract class _$BrandsBase extends $AsyncNotifier<List<Brand>> {
  FutureOr<List<Brand>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Brand>>, List<Brand>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Brand>>, List<Brand>>,
              AsyncValue<List<Brand>>,
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
abstract class _$Brands extends _$BrandsBase {
  /// The default key used by [persist].
  String get key {
    const resolvedKey = "Brands";
    return resolvedKey;
  }

  /// A variant of [persist], for JSON-specific encoding.
  ///
  /// You can override [key] to customize the key used for storage.
  PersistResult persist(
    FutureOr<Storage<String, String>> storage, {
    String? key,
    String Function(List<Brand> state)? encode,
    List<Brand> Function(String encoded)? decode,
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
                .map((e) => Brand.fromJson(e as Map<String, Object?>))
                .toList();
          },
      options: options,
    );
  }
}
