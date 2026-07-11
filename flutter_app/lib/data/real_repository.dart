import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import '../analytics/daily_pipeline.dart';
import '../analytics/raw_samples.dart';
import 'models.dart';
import 'repository.dart';

/// Repository backed by the REAL Whoop strap capture bundled in
/// `assets/data/real_raw.bin.gz`: ~2.7M genuine per-second sensor rows over 88
/// days (2026-01-28 → 2026-05-26), scored on-device by the ported NOOP
/// analytics ([DailyPipeline]). No fabricated numbers, real dates.
class RealRepository implements Repository {
  RealRepository._(this._days, this._workouts, this._vitals);

  static const String assetPath = 'assets/data/real_raw.bin.gz';

  @override
  final UserProfile profile = const UserProfile(name: 'Athlete');

  @override
  final SyncState syncState = SyncState.synced;

  @override
  final double strapBattery = 0.0; // no live strap in the replay build

  final List<DayRecord> _days;
  final List<Workout> _workouts;
  final List<VitalReading> _vitals;

  @override
  List<DayRecord> get days => _days;
  @override
  DayRecord get today => _days.last;
  @override
  List<Workout> get workouts => _workouts;
  @override
  List<VitalReading> get vitals => _vitals;

  /// Load + decode the capture and run the full analytics pipeline. Heavy but
  /// one-shot at startup. Throws if the asset is missing/corrupt (caller may
  /// fall back to a mock).
  static Future<RealRepository> load() async {
    final raw = await rootBundle.load(assetPath);
    final gzipped = raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes);
    final payload = Uint8List.fromList(gzip.decode(gzipped));
    final capture = RawCapture.decode(payload);

    const profile = UserProfile(name: 'Athlete');
    final days = DailyPipeline(profile).run(capture.days);
    if (days.isEmpty) throw StateError('real capture produced no days');

    return RealRepository._(days, const [], _buildVitals(days));
  }

  static List<VitalReading> _buildVitals(List<DayRecord> days) {
    final t = days.last;
    final asOf = t.date;
    final window = days.length >= 30 ? days.sublist(days.length - 30) : days;
    List<double> series(double Function(DayRecord) f) => window.map(f).toList();
    // Only the trustworthy channels: HRV (RMSSD over real beats) and resting HR.
    // Respiratory rate and SpO2 come from strap channels that are too
    // uncalibrated in this capture to publish, so the UI marks them "coming soon".
    return [
      VitalReading(label: 'HRV', value: t.hrv, unit: 'ms', asOf: asOf, series: series((d) => d.hrv)),
      VitalReading(
          label: 'Resting HR', value: t.rhr, unit: 'bpm', asOf: asOf, series: series((d) => d.rhr)),
    ];
  }
}
