import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/dashboard/layout.dart';
import 'package:fl_clash/views/dashboard/style.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'card.dart';

/// The traffic this machine has proxied, for the running profile or for all
/// of them, over a day, a week or a month. Its own card, below the others, so
/// nothing above it changes to make room.
class TrafficStatsCard extends ConsumerStatefulWidget {
  const TrafficStatsCard({super.key});

  @override
  ConsumerState<TrafficStatsCard> createState() => _TrafficStatsCardState();
}

class _TrafficStatsCardState extends ConsumerState<TrafficStatsCard> {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    // The ledger writes every ten seconds; the card reads on the same beat
    // instead of querying the table on every frame.
    _refresh = Timer.periodic(
      const Duration(seconds: 10),
      (_) => ref.invalidate(trafficUsageProvider),
    );
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(trafficUsageRangeProvider);
    final allProfiles = ref.watch(trafficUsageScopeProvider);
    final usage = ref.watch(trafficUsageProvider).value ?? (up: 0, down: 0);
    final labels = _TrafficLabels.forContext(context);
    final total = usage.up + usage.down;
    final scale = DashboardDensityScope.scaleOf(context);
    return DashboardCard(
      semanticLabel: labels.title,
      padding: EdgeInsets.fromLTRB(16, 12 * scale, 12, 14 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  labels.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardText.cardTitle(context),
                ),
              ),
              for (final item in TrafficRange.values)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _RangeChip(
                    label: labels.labelOf(item),
                    selected: item == range,
                    onTap: () => ref
                        .read(trafficUsageRangeProvider.notifier)
                        .select(item),
                  ),
                ),
            ],
          ),
          Text(
            dashboardTraffic(total),
            maxLines: 1,
            style: DashboardText.figure(context, AppTextStyle.title1),
          ),
          Row(
            spacing: 12,
            children: [
              Flexible(
                child: Text(
                  '↑ ${dashboardTraffic(usage.up)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardText.label(context),
                ),
              ),
              Flexible(
                child: Text(
                  '↓ ${dashboardTraffic(usage.down)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardText.label(context),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  labels.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardText.label(context),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    ref.read(trafficUsageScopeProvider.notifier).toggle(),
                child: Text(
                  allProfiles ? labels.allProfiles : labels.currentProfile,
                  maxLines: 1,
                  style: DashboardText.label(
                    context,
                    color: context.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: ShapeDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : DashboardColors.of(context).tone,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: DashboardText.label(
            context,
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// The card's own words: the app's l10n has no day/week/month labels yet, and
/// adding keys there means regenerating every locale for a four-word card.
class _TrafficLabels {
  const _TrafficLabels({
    required this.title,
    required this.today,
    required this.week,
    required this.month,
    required this.caption,
    required this.currentProfile,
    required this.allProfiles,
  });

  final String title;
  final String today;
  final String week;
  final String month;
  final String caption;
  final String currentProfile;
  final String allProfiles;

  factory _TrafficLabels.forContext(BuildContext context) {
    final title = context.appLocalizations.trafficUsage;
    final isChinese = Localizations.localeOf(context).languageCode == 'zh';
    return isChinese
        ? _TrafficLabels(
            title: title,
            today: '本日',
            week: '本周',
            month: '本月',
            caption: '本机统计 · 仅代理',
            currentProfile: '当前订阅 ⇄',
            allProfiles: '全部订阅 ⇄',
          )
        : _TrafficLabels(
            title: title,
            today: 'Today',
            week: 'Week',
            month: 'Month',
            caption: 'This machine · proxy only',
            currentProfile: 'This profile ⇄',
            allProfiles: 'All profiles ⇄',
          );
  }

  String labelOf(TrafficRange range) => switch (range) {
    TrafficRange.today => today,
    TrafficRange.week => week,
    TrafficRange.month => month,
  };
}
