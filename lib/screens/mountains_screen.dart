import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/mountains.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'trail_detail_screen.dart';

class MountainsScreen extends StatefulWidget {
  const MountainsScreen({super.key});

  @override
  State<MountainsScreen> createState() => _MountainsScreenState();
}

class _MountainsScreenState extends State<MountainsScreen> {
  final _search = TextEditingController();
  String _query = '';
  String _filter = 'For you';

  static const _filters = [
    'For you',
    'All',
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Trail> get _results {
    final q = _query.trim().toLowerCase();

    final base = _filter == 'For you'
        ? suggestedFor(HikerProfile.levelRank)
        : kMountains
            .where((m) => _filter == 'All' || m.difficulty == _filter)
            .toList();

    final filtered = base.where((m) {
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          m.region.toLowerCase().contains(q);
    }).toList();

    // "For you" is already ranked by level; everything else is alphabetical.
    if (_filter != 'For you') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back, size: 20),
                    label: Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.forest,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('All mountains',
                      style: Theme.of(context).textTheme.headlineMedium),
                  SizedBox(height: 4),
                  Text(
                    _filter == 'For you'
                        ? '${results.length} suited to a ${HikerProfile.levelName.toLowerCase()} hiker'
                        : '${results.length} of ${kMountains.length} destinations',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: 16),

                  TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(fontSize: 15, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'Search by name or province',
                      hintStyle: TextStyle(
                          color: AppColors.inkSoft, fontSize: 15),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 21, color: AppColors.inkSoft),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(Icons.close_rounded, size: 19),
                              color: AppColors.inkSoft,
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.pill,
                        borderSide: BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.pill,
                        borderSide:
                            BorderSide(color: AppColors.forest, width: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in _filters) ...[
                          _FilterChip(
                            label: f,
                            selected: _filter == f,
                            onTap: () => setState(() => _filter = f),
                          ),
                          SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14),

            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 42, color: AppColors.inkSoft),
                            const SizedBox(height: 12),
                            Text('No mountains match that search',
                                textAlign: TextAlign.center,
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          MountainRow(mountain: results[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.forest : AppColors.card,
      borderRadius: AppRadius.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: selected ? AppColors.forest : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared with the dashboard so both lists look identical.
class MountainRow extends StatelessWidget {
  final Trail mountain;
  const MountainRow({super.key, required this.mountain});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TrailDetailScreen(trail: mountain)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: AppRadius.field,
            ),
            child: Icon(Icons.terrain_rounded,
                size: 22, color: AppColors.forest),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mountain.name,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '${mountain.region} Â· ${mountain.duration}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: mountain.levelColor,
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              mountain.difficulty,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}










