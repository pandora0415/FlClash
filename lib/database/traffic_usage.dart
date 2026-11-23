part of 'database.dart';

/// One row per profile and day: the bytes this machine pushed and pulled
/// through the proxy that day. The core only keeps a total since its own
/// start, so this is the record the "today/this week/this month" card reads.
class TrafficUsageRecords extends Table {
  IntColumn get profileId => integer()();

  /// Local calendar day, `yyyy-MM-dd`, so a month is a string range.
  TextColumn get day => text()();

  IntColumn get up => integer().withDefault(const Constant(0))();

  IntColumn get down => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {profileId, day};
}

typedef TrafficUsageSum = ({int up, int down});

@DriftAccessor(tables: [TrafficUsageRecords])
class TrafficUsageDao extends DatabaseAccessor<Database>
    with _$TrafficUsageDaoMixin {
  TrafficUsageDao(super.attachedDatabase);

  /// Adds to the row the profile and day already have, so a flush never
  /// overwrites what the one before it wrote.
  Future<void> addDelta({
    required int profileId,
    required String day,
    required int up,
    required int down,
  }) async {
    if (up <= 0 && down <= 0) {
      return;
    }
    await attachedDatabase.customStatement(
      'INSERT INTO traffic_usage_records (profile_id, day, up, down) '
      'VALUES (?, ?, ?, ?) '
      'ON CONFLICT(profile_id, day) DO UPDATE SET '
      'up = up + excluded.up, down = down + excluded.down',
      [profileId, day, up, down],
    );
  }

  /// [profileId] null counts every profile, which is what the "all
  /// subscriptions" switch shows.
  Future<TrafficUsageSum> sumRange({
    int? profileId,
    required String from,
    required String to,
  }) async {
    final row = await attachedDatabase
        .customSelect(
          'SELECT COALESCE(SUM(up), 0) AS total_up, '
          'COALESCE(SUM(down), 0) AS total_down '
          'FROM traffic_usage_records WHERE day >= ? AND day <= ?'
          '${profileId == null ? '' : ' AND profile_id = ?'}',
          variables: _variables(from, to, profileId),
        )
        .getSingle();
    return (up: row.read<int>('total_up'), down: row.read<int>('total_down'));
  }

  Future<Map<int, TrafficUsageSum>> sumRangeByProfile({
    required String from,
    required String to,
  }) async {
    final rows = await attachedDatabase
        .customSelect(
          'SELECT profile_id, COALESCE(SUM(up), 0) AS total_up, '
          'COALESCE(SUM(down), 0) AS total_down '
          'FROM traffic_usage_records WHERE day >= ? AND day <= ? '
          'GROUP BY profile_id',
          variables: [Variable(from), Variable(to)],
        )
        .get();
    return {
      for (final row in rows)
        row.read<int>('profile_id'): (
          up: row.read<int>('total_up'),
          down: row.read<int>('total_down'),
        ),
    };
  }

  Future<List<({String day, int up, int down})>> daysBetween({
    int? profileId,
    required String from,
    required String to,
  }) async {
    final rows = await attachedDatabase
        .customSelect(
          'SELECT day, COALESCE(SUM(up), 0) AS total_up, '
          'COALESCE(SUM(down), 0) AS total_down '
          'FROM traffic_usage_records WHERE day >= ? AND day <= ?'
          '${profileId == null ? '' : ' AND profile_id = ?'} '
          'GROUP BY day ORDER BY day',
          variables: _variables(from, to, profileId),
        )
        .get();
    return [
      for (final row in rows)
        (
          day: row.read<String>('day'),
          up: row.read<int>('total_up'),
          down: row.read<int>('total_down'),
        ),
    ];
  }

  /// Three months: the running month and the two before it.
  Future<void> purgeBefore(String day) async {
    await attachedDatabase.customStatement(
      'DELETE FROM traffic_usage_records WHERE day < ?',
      [day],
    );
  }

  /// The bound values of a range query, with the profile only when one is
  /// named: its `?` is then in the statement too.
  static List<Variable> _variables(String from, String to, int? profileId) {
    final variables = <Variable>[Variable(from), Variable(to)];
    if (profileId != null) {
      variables.add(Variable(profileId));
    }
    return variables;
  }
}
