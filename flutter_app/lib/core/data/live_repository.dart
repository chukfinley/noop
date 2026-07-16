import 'dart:isolate';
import 'dart:math' as math;

import 'package:noop/core/analytics/engine_registry.dart';
import 'package:noop/core/analytics/raw_samples.dart';
import 'package:noop/core/data/db/database.dart' show AppDatabase;
import 'package:noop/core/data/models.dart';
import 'package:noop/core/data/repository.dart';
import 'package:noop/core/state/prefs.dart' show HrvWindow, Prefs;

/// Repository backed PURELY by live strap-synced data in the local drift store —
/// no bundled history. It starts EMPTY and grows as the WHOOP strap offloads its
/// sensor rows into the stream tables (`hrSample` / `rrInterval` / `gravitySample`
/// / …). The synced per-second rows are regrouped by LOCAL calendar day and run
/// through the SAME ported analytics ([DailyPipeline]) the replay build uses, so
/// the scores are identical logic — only the source differs (drift, not the
/// bundled asset). Personal EWMA baselines recalibrate naturally over the first
/// days (WHOOP's ~4-day calibration).
///
/// A snapshot: [load] queries the tables once and scores every day. To reflect a
/// new sync, build a fresh one and swap it into `repositoryProvider` (see
/// `main()`'s debounced reload on the whoop stream tables).
class LiveRepository implements Repository {
  LiveRepository._(this.profile, this._daysByEngine, this._vitals);

  @override
  final UserProfile profile;

  @override
  final SyncState syncState = SyncState.synced;

  /// Live strap battery is surfaced through its own BLE provider on Today, so
  /// the repository reports none here (never a fabricated level).
  @override
  final double strapBattery = 0.0;

  /// Every registered engine's scored days, keyed by engine id. All engines run
  /// over the SAME raw sync — nothing is deleted or re-fetched to switch.
  final Map<String, List<DayRecord>> _daysByEngine;
  final List<VitalReading> _vitals;

  @override
  Map<String, List<DayRecord>> get daysByEngine => _daysByEngine;

  /// The default engine's scored days (the app-wide fallback).
  @override
  List<DayRecord> get days => _daysByEngine[defaultEngineId] ?? const [];

  /// The most recent scored day. Callers must guard on [days] being empty first
  /// (the cold-start live state has no days at all).
  @override
  DayRecord get today => days.last;

  /// No activity source is decoded from the live stream yet → always empty
  /// (never fabricated). Workouts land when the activity decoder is wired.
  @override
  List<Workout> get workouts => const [];

  @override
  List<VitalReading> get vitals => _vitals;

  /// An EMPTY live repository — the cold-start state before any strap has synced,
  /// and the safe fallback when the DB can't be opened (real-or-nothing: we never
  /// fall back to mock/fake numbers on device).
  static LiveRepository empty({UserProfile profile = const UserProfile()}) =>
      LiveRepository._(profile, const {}, const []);

  /// Query the synced stream tables, regroup per local day, and score every day
  /// through EVERY registered [AnalysisEngine] (our own + OpenStrap + …). Each
  /// engine's scores are kept side-by-side so the UI can switch between them
  /// with no re-analysis. Returns an empty repository when nothing is synced.
  static Future<LiveRepository> load(
    AppDatabase db, {
    UserProfile profile = const UserProfile(),
    HrvWindow hrvWindow = HrvWindow.wholeNight,
  }) async {
    final days = await _buildDays(db);
    if (days.isEmpty) return LiveRepository._(profile, const {}, const []);
    // Score ONLY the engines we actually need — the default (the app-wide
    // fallback) plus the one the user is currently viewing. Running every engine
    // on every debounced sync reload was the heat/lag culprit: OpenStrap's
    // per-night Lomb-Scargle is expensive, and re-doing it constantly over a
    // large synced store pegged the CPU. A not-yet-computed engine is scored on
    // demand when the user switches to it (main.dart re-loads on that change).
    final wanted = <String>{defaultEngineId, Prefs.instance.analysisEngineId};
    // Compute OFF the main isolate so the heavy math never touches the render
    // thread; `Isolate.run` copies the raw days out and the scored days back.
    final byEngine =
        await Isolate.run(() => _scoreEngines(days, profile, hrvWindow, wanted));
    if (byEngine.isEmpty) return LiveRepository._(profile, const {}, const []);
    final primary = byEngine[defaultEngineId] ?? byEngine.values.first;
    return LiveRepository._(profile, byEngine, _buildVitals(primary));
  }

  /// Run the [wanted] engines over [days] and collect their scored days by engine
  /// id. Pure + isolate-safe (no DB, no Flutter bindings) so it can run on a
  /// background isolate — see [load].
  static Map<String, List<DayRecord>> _scoreEngines(
    List<RawDay> days,
    UserProfile profile,
    HrvWindow hrvWindow,
    Set<String> wanted,
  ) {
    final byEngine = <String, List<DayRecord>>{};
    for (final engine in engineRegistry) {
      if (!wanted.contains(engine.id)) continue;
      final scored = engine.analyze(days, profile, hrvWindow: hrvWindow);
      if (scored.isNotEmpty) byEngine[engine.id] = scored;
    }
    return byEngine;
  }

  /// Regroup the drift stream rows into [RawDay]s (local calendar days) shaped
  /// the same shape the pipeline consumes:
  /// one [RawSample] per unix-second, merging the second's HR, its beat-to-beat
  /// RR intervals and its accel-magnitude.
  static Future<List<RawDay>> _buildDays(AppDatabase db) async {
    final hrRows = await db.select(db.whoopHrSamples).get();
    if (hrRows.isEmpty) return const [];
    final rrRows = await db.select(db.whoopRrIntervals).get();
    final gravRows = await db.select(db.whoopGravitySamples).get();
    final sleepStateRows = await db.select(db.whoopSleepStateSamples).get();

    // ts (unix seconds) → mutable per-second builder.
    final byTs = <int, _SampleBuilder>{};
    _SampleBuilder at(int ts) => byTs.putIfAbsent(ts, () => _SampleBuilder(ts));

    for (final r in hrRows) {
      if (r.bpm > 0) at(r.ts).hr = r.bpm;
    }
    for (final r in rrRows) {
      if (r.rrMs > 0) at(r.ts).rr.add(r.rrMs);
    }
    // The strap's OWN per-second sleep_state (#175) — ground truth. Carried
    // verbatim (0 = awake, non-zero = a sleep stage) so the pipeline anchors the
    // sleep window to what the band actually recorded instead of re-deriving it
    // from HR. A second with a state but no HR still seeds a builder.
    for (final r in sleepStateRows) {
      at(r.ts).sleepState = r.state;
    }
    for (final r in gravRows) {
      // |accel| magnitude in g — ~1.0 at rest. The pipeline treats the deviation
      // from that 1 g resting magnitude as motion, exactly like the asset's `mv`
      // channel, so a still wrist maps to ≈0. (dynamicAccel is a separate motion
      // scalar; the gravity-vector magnitude keeps parity with the asset.)
      final mag = math.sqrt(r.x * r.x + r.y * r.y + r.z * r.z);
      at(r.ts).mv = mag;
    }

    // Bucket by LOCAL calendar day (the device's own timezone), oldest → newest.
    final buckets = <int, List<RawSample>>{};
    final tss = byTs.keys.toList()..sort();
    for (final ts in tss) {
      final local = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      final key =
          DateTime(local.year, local.month, local.day).millisecondsSinceEpoch;
      (buckets[key] ??= <RawSample>[]).add(byTs[ts]!.build());
    }
    final keys = buckets.keys.toList()..sort();
    return [
      for (final k in keys)
        RawDay(DateTime.fromMillisecondsSinceEpoch(k), buckets[k]!),
    ];
  }

  /// The trustworthy live vitals — HRV (RMSSD over the real beats) and resting
  /// HR. Respiratory rate / SpO2 stay "coming soon" (no calibrated live source).
  static List<VitalReading> _buildVitals(List<DayRecord> days) {
    final t = days.last;
    final asOf = t.date;
    final window = days.length >= 30 ? days.sublist(days.length - 30) : days;
    List<double> series(double Function(DayRecord) f) => window.map(f).toList();
    return [
      VitalReading(
          label: 'HRV', value: t.hrv, unit: 'ms', asOf: asOf, series: series((d) => d.hrv)),
      VitalReading(
          label: 'Resting HR', value: t.rhr, unit: 'bpm', asOf: asOf, series: series((d) => d.rhr)),
    ];
  }
}

/// Accumulates one unix-second's HR / RR / accel into a single [RawSample].
class _SampleBuilder {
  _SampleBuilder(this.ts);
  final int ts;
  int hr = 0;
  double? mv;
  int? sleepState;
  final List<int> rr = [];

  RawSample build() => RawSample(
        ts: ts,
        hr: hr,
        sleepState: sleepState,
        // Raw SpO2 ADC is uncalibrated in the capture → "coming soon", never
        // fabricated. Left absent so the pipeline excludes it.
        spo2: 0,
        rrCount: rr.length > 3 ? 3 : rr.length,
        rr1: rr.isNotEmpty ? rr[0] : 0,
        rr2: rr.length > 1 ? rr[1] : 0,
        rr3: rr.length > 2 ? rr[2] : 0,
        // A second with no accel sample carries NO movement — never the 1 g
        // resting magnitude it used to default to. HR and gravity are merged onto
        // one row here but are not sampled together (a 4.0 offload banks HR
        // densely and gravity coarsely), so that default fabricated perfect
        // stillness for most seconds of a real night and fed it to the guards
        // that decide whether the wearer woke up. See [RawSample.movement].
        movement: mv,
      );
}
