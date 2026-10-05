import "package:flutter/material.dart";
import "../data/mock_data.dart";
import "../services/firebase_service.dart";
import "../theme/app_theme.dart";
import "../widgets/app_widgets.dart";
import "hazard_report_screen.dart";
import "sos_screen.dart";

/// Which slice of the week's reports the hiker is looking at.
enum _RiskFilter { all, high, caution, minor }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  _RiskFilter _filter = _RiskFilter.all;

  bool _matches(TrailRisk r) {
    switch (_filter) {
      case _RiskFilter.all:
        return true;
      case _RiskFilter.high:
        return r.level == AlertLevel.critical;
      case _RiskFilter.caution:
        return r.level == AlertLevel.caution;
      case _RiskFilter.minor:
        return r.level == AlertLevel.notice;
    }
  }

  String get _emptyFilterMessage {
    switch (_filter) {
      case _RiskFilter.high:
        return "No high-risk mountains this week. That is the good outcome.";
      case _RiskFilter.caution:
        return "Nothing needing caution right now.";
      case _RiskFilter.minor:
        return "No minor issues reported.";
      case _RiskFilter.all:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<TrailRisk>>(
        stream: FirebaseService.trailRiskStream(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <TrailRisk>[];
          final loading =
              snapshot.connectionState == ConnectionState.waiting;
          final failed = snapshot.hasError;

          final high =
              all.where((r) => r.level == AlertLevel.critical).length;
          final caution =
              all.where((r) => r.level == AlertLevel.caution).length;
          final minor =
              all.where((r) => r.level == AlertLevel.notice).length;
          final totalReports =
              all.fold<int>(0, (sum, r) => sum + r.reports.length);

          final shown = all.where(_matches).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Trail conditions",
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      loading
                          ? "Checking reports..."
                          : failed
                              ? "Could not load reports"
                              : all.isEmpty
                                  ? "No hazards reported this week"
                                  : "$totalReports "
                                      "${totalReports == 1 ? "report" : "reports"} "
                                      "across ${all.length} "
                                      "${all.length == 1 ? "mountain" : "mountains"}, "
                                      "last 7 days",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Tappable counters. These answer "is anything wrong?" at a
              // glance and narrow the list in one tap.
              if (!loading && !failed && all.isNotEmpty) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FilterTile(
                          value: all.length,
                          label: "all",
                          color: AppColors.forest,
                          icon: Icons.landscape_outlined,
                          selected: _filter == _RiskFilter.all,
                          onTap: () =>
                              setState(() => _filter = _RiskFilter.all),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _FilterTile(
                          value: high,
                          label: "high risk",
                          color: AppColors.alert,
                          icon: Icons.priority_high_rounded,
                          selected: _filter == _RiskFilter.high,
                          onTap: () =>
                              setState(() => _filter = _RiskFilter.high),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _FilterTile(
                          value: caution,
                          label: "caution",
                          color: AppColors.blaze,
                          icon: Icons.warning_amber_rounded,
                          selected: _filter == _RiskFilter.caution,
                          onTap: () =>
                              setState(() => _filter = _RiskFilter.caution),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _FilterTile(
                          value: minor,
                          label: "minor",
                          color: AppColors.inkSoft,
                          icon: Icons.info_outline_rounded,
                          selected: _filter == _RiskFilter.minor,
                          onTap: () =>
                              setState(() => _filter = _RiskFilter.minor),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_filter != _RiskFilter.all) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt_outlined,
                            size: 14, color: AppColors.inkSoft),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Showing ${shown.length} of ${all.length} mountains",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _filter = _RiskFilter.all),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.forest,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text("Clear",
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 14),

              Expanded(
                child: loading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: AppColors.forest))
                    : failed
                        ? const _LoadFailed()
                        : all.isEmpty
                            ? const _NoAlerts()
                            : shown.isEmpty
                                ? _FilterEmpty(
                                    message: _emptyFilterMessage,
                                    onClear: () => setState(
                                        () => _filter = _RiskFilter.all),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 0, 20, 20),
                                    itemCount: shown.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, i) =>
                                        _TrailRiskCard(risk: shown[i]),
                                  ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: "Emergency SOS",
                      icon: Icons.sos_rounded,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SosScreen()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SecondaryButton(
                      label: "Report a hazard",
                      icon: Icons.flag_outlined,
                      color: AppColors.blaze,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const HazardReportScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A counter that doubles as a filter. Zero counts are dimmed but still
/// tappable, so the layout never shifts as reports come and go.
class _FilterTile extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTile({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final empty = value == 0;
    final tint = empty ? AppColors.inkSoft : color;

    return Material(
      color: selected ? tint.withAlpha(30) : AppColors.card,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(
              color: selected ? tint : AppColors.line,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: tint),
              const SizedBox(height: 5),
              Text(
                "$value",
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: tint,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One mountain, with its hazards collapsed into a single risk reading.
class _TrailRiskCard extends StatefulWidget {
  final TrailRisk risk;
  const _TrailRiskCard({required this.risk});

  @override
  State<_TrailRiskCard> createState() => _TrailRiskCardState();
}

class _TrailRiskCardState extends State<_TrailRiskCard> {
  bool _expanded = false;

  String _ago(DateTime? t) {
    if (t == null) return "just now";
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return "just now";
    if (d.inMinutes < 60) return "${d.inMinutes} min ago";
    if (d.inHours < 24) {
      return "${d.inHours} ${d.inHours == 1 ? "hour" : "hours"} ago";
    }
    return "${d.inDays} ${d.inDays == 1 ? "day" : "days"} ago";
  }

  @override
  Widget build(BuildContext context) {
    final risk = widget.risk;

    final counts = <String, int>{};
    for (final r in risk.reports) {
      counts[r.type] = (counts[r.type] ?? 0) + 1;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.card,
        border: Border.all(color: risk.color, width: 1.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: risk.color.withAlpha(36),
                      borderRadius: AppRadius.field,
                    ),
                    child: Icon(
                      risk.level == AlertLevel.critical
                          ? Icons.priority_high_rounded
                          : risk.level == AlertLevel.caution
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline_rounded,
                      size: 22,
                      color: risk.color,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(risk.trailName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: risk.color.withAlpha(36),
                                borderRadius: AppRadius.pill,
                              ),
                              child: Text(
                                risk.verdict,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: risk.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                "${risk.reports.length} "
                                "${risk.reports.length == 1 ? "report" : "reports"}"
                                " - ${_ago(risk.latest)}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.inkSoft,
                  ),
                ],
              ),
            ),
          ),

          if (!_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 13),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: counts.entries
                      .map((e) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.fill,
                              borderRadius: AppRadius.pill,
                            ),
                            child: Text(
                              e.value > 1 ? "${e.key} x${e.value}" : e.key,
                              style: TextStyle(
                                  fontSize: 11.5, color: AppColors.inkSoft),
                            ),
                          ))
                      .toList(),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 12),
              child: Column(
                children: [
                  for (final r in risk.reports) ...[
                    Divider(height: 1, color: AppColors.line),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(r.icon, size: 17, color: r.markerColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.type,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    )),
                                if (r.description.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(r.description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                                const SizedBox(height: 3),
                                Text(
                                  "${r.reportedByName} - ${_ago(r.reportedAt)}",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.inkSoft),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown when a filter matches nothing, rather than a blank screen.
class _FilterEmpty extends StatelessWidget {
  final String message;
  final VoidCallback onClear;

  const _FilterEmpty({required this.message, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_off_outlined,
                size: 38, color: AppColors.inkSoft),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onClear,
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.forest),
              child: const Text("Show all mountains"),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiet reassurance rather than an error: no alerts is good news.
class _NoAlerts extends StatelessWidget {
  const _NoAlerts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.mist,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded,
                  size: 42, color: AppColors.forest),
            ),
            const SizedBox(height: 20),
            Text("All clear",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              "No hazards reported in the last seven days. Reports older "
              "than a week are cleared automatically.",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.inkSoft),
            const SizedBox(height: 16),
            Text("Could not load reports",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              "Check your connection. You can still send an SOS or file a "
              "report below.",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}
