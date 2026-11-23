// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../traffic_usage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TrafficUsageRange)
final trafficUsageRangeProvider = TrafficUsageRangeProvider._();

final class TrafficUsageRangeProvider
    extends $NotifierProvider<TrafficUsageRange, TrafficRange> {
  TrafficUsageRangeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trafficUsageRangeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trafficUsageRangeHash();

  @$internal
  @override
  TrafficUsageRange create() => TrafficUsageRange();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrafficRange value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrafficRange>(value),
    );
  }
}

String _$trafficUsageRangeHash() => r'50db8f43a41e159e11bf38bb4f4f986eb679b40c';

abstract class _$TrafficUsageRange extends $Notifier<TrafficRange> {
  TrafficRange build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TrafficRange, TrafficRange>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TrafficRange, TrafficRange>,
              TrafficRange,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(TrafficUsageScope)
final trafficUsageScopeProvider = TrafficUsageScopeProvider._();

final class TrafficUsageScopeProvider
    extends $NotifierProvider<TrafficUsageScope, bool> {
  TrafficUsageScopeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trafficUsageScopeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trafficUsageScopeHash();

  @$internal
  @override
  TrafficUsageScope create() => TrafficUsageScope();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$trafficUsageScopeHash() => r'f18a97150a5157118282ff7267363dbd684c6870';

abstract class _$TrafficUsageScope extends $Notifier<bool> {
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

@ProviderFor(trafficUsage)
final trafficUsageProvider = TrafficUsageProvider._();

final class TrafficUsageProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrafficUsageSum>,
          TrafficUsageSum,
          FutureOr<TrafficUsageSum>
        >
    with $FutureModifier<TrafficUsageSum>, $FutureProvider<TrafficUsageSum> {
  TrafficUsageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trafficUsageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trafficUsageHash();

  @$internal
  @override
  $FutureProviderElement<TrafficUsageSum> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TrafficUsageSum> create(Ref ref) {
    return trafficUsage(ref);
  }
}

String _$trafficUsageHash() => r'972eda4678a2f08bae7b2d728ed55e6b0e7ce9ea';
