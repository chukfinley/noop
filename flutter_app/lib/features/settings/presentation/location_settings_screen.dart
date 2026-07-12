import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/weather.dart';
import 'package:noop/core/state/prefs.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/shared/widgets/scaffold.dart';

/// Weather location picker — search a city, tap to pin it. The pinned place is
/// persisted and used by the home weather chip instead of the coarse IP guess.
class LocationSettingsScreen extends ConsumerStatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  ConsumerState<LocationSettingsScreen> createState() =>
      _LocationSettingsScreenState();
}

class _LocationSettingsScreenState
    extends ConsumerState<LocationSettingsScreen> {
  final TextEditingController _ctrl = TextEditingController();
  List<WeatherLocation> _results = [];
  String _lastQuery = '';
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    final q = value.trim();
    _lastQuery = q;
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final found = await searchLocations(q);
    // Ignore out-of-order responses: only the latest query wins.
    if (!mounted || q != _lastQuery) return;
    setState(() {
      _results = found;
      _loading = false;
    });
  }

  Future<void> _select(WeatherLocation loc) async {
    ref.read(weatherLocationProvider.notifier).state = loc;
    await Prefs.instance.setWeatherLocation(loc.lat, loc.lon, loc.name);
    if (mounted) Navigator.of(context).maybePop();
  }

  void _reset() {
    ref.read(weatherLocationProvider.notifier).state = null;
    Prefs.instance.setWeatherLocation(null, null, null);
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(weatherLocationProvider);
    return ScreenScaffold(
      title: 'Weather location',
      children: [
        // Current selection summary.
        Material(
          color: Palette.fillRaised,
          borderRadius: BorderRadius.circular(Metrics.cornerLarge),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Metrics.space14, vertical: Metrics.space12),
            child: Row(
              children: [
                Icon(Icons.my_location_rounded,
                    color: Palette.metricCyan, size: 22),
                const SizedBox(width: Metrics.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current location',
                          style: NoopType.caption
                              .copyWith(color: Palette.textTertiary)),
                      const SizedBox(height: 2),
                      Text(
                        (loc != null && loc.name.isNotEmpty)
                            ? loc.name
                            : 'Automatic (from IP)',
                        style: NoopType.body.copyWith(
                            color: Palette.textPrimary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (loc != null)
                  TextButton(
                    onPressed: _reset,
                    child: Text('Automatic',
                        style: NoopType.footnote
                            .copyWith(color: Palette.metricCyan)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Metrics.space12),
        // Search field.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Metrics.space14),
          decoration: BoxDecoration(
            color: Palette.fillRaised,
            borderRadius: BorderRadius.circular(Metrics.cornerLarge),
          ),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.search,
            style: NoopType.body.copyWith(color: Palette.textPrimary),
            cursorColor: Palette.accent,
            onChanged: _search,
            onSubmitted: _search,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Search city…',
              hintStyle:
                  NoopType.body.copyWith(color: Palette.textTertiary),
              icon: Icon(Icons.search_rounded, color: Palette.textTertiary),
            ),
          ),
        ),
        const SizedBox(height: Metrics.space12),
        if (_loading)
          Padding(
            padding: const EdgeInsets.only(top: Metrics.space16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Palette.accent),
              ),
            ),
          )
        else
          // One Column so ScreenScaffold's screenRowSpacing isn't inserted
          // between every result — the rows sit tight together.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _results.length; i++) ...[
                _ResultRow(loc: _results[i], onTap: () => _select(_results[i])),
                if (i != _results.length - 1) const SizedBox(height: 6),
              ],
            ],
          ),
      ],
    );
  }
}

/// A single tappable geocoding result — a filled row, no border.
class _ResultRow extends StatelessWidget {
  final WeatherLocation loc;
  final VoidCallback onTap;
  const _ResultRow({required this.loc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.fillRaised,
      borderRadius: BorderRadius.circular(Metrics.cornerBadge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Metrics.space14, vertical: Metrics.space12),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: Palette.metricCyan, size: 20),
              const SizedBox(width: Metrics.space12),
              Expanded(
                child: Text(loc.name,
                    style: NoopType.body.copyWith(color: Palette.textPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
