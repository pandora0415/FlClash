import 'dart:async';

import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/traffic_usage.g.dart';

/// Hand-rolled instead of `DateFormat`: the app sets a non-English
/// `Intl.defaultLocale` without loading its date symbols, and a numeric
/// pattern still throws there.
String dayKey(DateTime time) {
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '${time.year}-$month-$day';
}

enum TrafficRange {
  today,
  week,
  month;

  /// The first day of the range, inclusive, in this machine's own calendar.
  /// A week starts on Monday.
  String get fromDay {
    final now = DateTime.now();
    return switch (this) {
      TrafficRange.today => dayKey(now),
      TrafficRange.week => dayKey(
        now.subtract(Duration(days: now.weekday - 1)),
      ),
      TrafficRange.month => dayKey(DateTime(now.year, now.month, 1)),
    };
  }
}

class _Bucket {
  _Bucket(this.profileId, this.day);

  final int profileId;
  final String day;
  int up = 0;
  int down = 0;
}

/// Adds this machine's proxy bytes to one row per profile and day.
///
/// The core keeps a total only since its own start, so every sample is a
/// delta against the previous one. A total that went backwards means the core
/// restarted: that sample then counts in full instead of as a difference.
/// A day that turned over counts nothing: those bytes were the last day's.
class TrafficLedger {
  int _up = 0;
  int _down = 0;
  int? _profileId;
  String? _day;
  String? _purgedDay;
  final _pending = <String, _Bucket>{};
  Timer? _flushTimer;

  void sample({required int profileId, required num up, required num down}) {
    final currentUp = up.toInt();
    final currentDown = down.toInt();
    final day = dayKey(DateTime.now());
    final switched = _profileId != profileId;
    final reset = currentUp < _up || currentDown < _down;
    final rollover = !switched && !reset && _day != null && _day != day;
    final deltaUp = (switched || reset)
        ? currentUp
        : (rollover ? 0 : currentUp - _up);
    final deltaDown = (switched || reset)
        ? currentDown
        : (rollover ? 0 : currentDown - _down);
    if (switched) {
      _profileId = profileId;
      // What the old profile had not written yet belongs to it, not to this one.
      unawaited(flush());
    }
    _up = currentUp;
    _down = currentDown;
    _day = day;
    if (deltaUp <= 0 && deltaDown <= 0) {
      return;
    }
    unawaited(_purgeIfNewDay(day));
    final bucket = _pending['$profileId|$day'] ??= _Bucket(profileId, day);
    bucket
      ..up += deltaUp
      ..down += deltaDown;
    _flushTimer ??= Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(flush()),
    );
  }

  /// One write per profile and day, so a minute of traffic costs a handful of
  /// statements rather than one per sample.
  Future<void> flush() async {
    if (_pending.isEmpty) {
      return;
    }
    final pending = _pending.values.toList();
    _pending.clear();
    try {
      for (final bucket in pending) {
        await database.trafficUsageDao.addDelta(
          profileId: bucket.profileId,
          day: bucket.day,
          up: bucket.up,
          down: bucket.down,
        );
      }
    } catch (_) {
      // A failed write must not take the bytes with it: put them back so the
      // next flush retries them.
      for (final bucket in pending) {
        final key = '${bucket.profileId}|${bucket.day}';
        final kept = _pending[key];
        if (kept == null) {
          _pending[key] = bucket;
        } else {
          kept
            ..up += bucket.up
            ..down += bucket.down;
        }
      }
    }
  }

  /// Keeps the running month and the two before it: one purge a day is enough.
  Future<void> _purgeIfNewDay(String day) async {
    if (_purgedDay == day) {
      return;
    }
    _purgedDay = day;
    final now = DateTime.now();
    try {
      await database.trafficUsageDao.purgeBefore(
        dayKey(DateTime(now.year, now.month - 2, 1)),
      );
    } catch (_) {
      // A missed purge only costs a few rows; the next day tries again.
      _purgedDay = null;
    }
  }
}

/// No dispose: it lives as long as the app does, as the core's totals do.
final trafficLedger = TrafficLedger();

@Riverpod(keepAlive: true)
class TrafficUsageRange extends _$TrafficUsageRange {
  @override
  TrafficRange build() => TrafficRange.month;

  void select(TrafficRange value) => state = value;
}

@Riverpod(keepAlive: true)
class TrafficUsageScope extends _$TrafficUsageScope {
  /// False while the card counts the running profile only.
  @override
  bool build() => false;

  void toggle() => state = !state;
}

@riverpod
Future<TrafficUsageSum> trafficUsage(Ref ref) async {
  final range = ref.watch(trafficUsageRangeProvider);
  final allProfiles = ref.watch(trafficUsageScopeProvider);
  final currentProfile = ref.watch(currentProfileProvider);
  final profileId = allProfiles ? null : currentProfile?.id;
  if (!allProfiles && profileId == null) {
    return (up: 0, down: 0);
  }
  return database.trafficUsageDao.sumRange(
    profileId: profileId,
    from: range.fromDay,
    to: dayKey(DateTime.now()),
  );
}
