// Pins [LiveReloadScheduler] — the metering that decides how often a strap
// offload is allowed to trigger a full [LiveRepository.load].
//
// The thing being measured is DUTY CYCLE: what fraction of a sync's wall clock is
// spent inside a rebuild. A rebuild is ~95 % main-isolate work (19eb1b2a), so duty
// cycle is, near enough, sustained CPU occupancy — the user's overheating.
//
// Driven on VIRTUAL time. Real timers would make a 5-minute offload take five
// minutes and still be flaky; the scheduler takes its clock and its timer factory
// as parameters precisely so the policy can be simulated exactly. [_Sim] below is
// the whole harness: an ordered queue of due callbacks and an integer clock.
//
// `oldPolicy` is the metering this replaced, transcribed verbatim, so BEFORE and
// AFTER are measured on the identical timeline rather than argued about.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/main.dart';

// ---------------------------------------------------------------------------
// Virtual-time harness
// ---------------------------------------------------------------------------

class _FakeTimer implements Timer {
  _FakeTimer(this.due, this.cb, this._sim);
  final int due; // ms on the sim clock
  final void Function() cb;
  final _Sim _sim;
  bool _cancelled = false;

  @override
  void cancel() => _cancelled = true;
  @override
  bool get isActive => !_cancelled && _sim.nowMs < due;
  @override
  int get tick => 0;
}

/// A deterministic clock + timer queue. Time only moves when [advanceTo] says so,
/// and every callback due at or before the target fires in due order.
class _Sim {
  int nowMs = 0;
  final _timers = <_FakeTimer>[];

  DateTime clock() => DateTime.fromMillisecondsSinceEpoch(nowMs);

  Timer timer(Duration d, void Function() cb) {
    final t = _FakeTimer(nowMs + d.inMilliseconds, cb, this);
    _timers.add(t);
    return t;
  }

  /// Runs the queue forward to [targetMs]. Microtasks are drained between steps
  /// so the scheduler's `whenComplete` continuation (which is what applies the
  /// cooldown) actually runs before the next timer fires.
  Future<void> advanceTo(int targetMs) async {
    while (true) {
      _timers.removeWhere((t) => t._cancelled);
      final due = _timers.where((t) => t.due <= targetMs).toList()
        ..sort((a, b) => a.due.compareTo(b.due));
      if (due.isEmpty) break;
      final t = due.first;
      _timers.remove(t);
      nowMs = t.due > nowMs ? t.due : nowMs;
      t.cb();
      await _drain();
    }
    nowMs = targetMs;
    await _drain();
  }

  Future<void> _drain() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}

/// Records every rebuild the policy under test starts, and burns [costMs] of
/// VIRTUAL time doing it — the load completes by a timer, exactly like a real
/// async load completes off the event loop.
class _Load {
  _Load(this._sim, this.costMs);
  final _Sim _sim;
  final int costMs;
  final starts = <int>[];
  final ends = <int>[];
  int busyMs = 0;

  Future<void> call() {
    starts.add(_sim.nowMs);
    busyMs += costMs;
    final done = Completer<void>();
    _sim.timer(Duration(milliseconds: costMs), () {
      ends.add(_sim.nowMs);
      done.complete();
    });
    return done.future;
  }
}

/// The policy [LiveReloadScheduler] replaced, transcribed from main.dart as it
/// stood: a 2 s trailing-edge debounce that cancels and re-arms on every tick,
/// plus a single-flight guard whose trailing rebuild runs the instant the current
/// one finishes.
class _OldPolicy {
  _OldPolicy(this._sim, this._load);
  final _Sim _sim;
  final Future<void> Function() _load;
  Timer? _debounce;
  var _loading = false;
  var _pending = false;

  Future<void> reload() async {
    if (_loading) {
      _pending = true;
      return;
    }
    _loading = true;
    try {
      await _load();
    } finally {
      _loading = false;
      if (_pending) {
        _pending = false;
        unawaited(reload());
      }
    }
  }

  void tick() {
    _debounce?.cancel();
    _debounce = _sim.timer(const Duration(milliseconds: 2000), reload);
  }
}

/// What a policy did with one simulated offload.
class _Result {
  _Result(this._load, this.spanMs);
  final _Load _load;
  final int spanMs;

  int get rebuilds => _load.starts.length;
  int get busyMs => _load.busyMs;
  int? get firstAtMs => _load.starts.isEmpty ? null : _load.starts.first;

  /// Occupancy across the whole simulated window, idle tail included.
  double get duty => busyMs / spanMs;

  /// Occupancy while the policy was actually working — first rebuild started to
  /// last one finished. This is the number the phone feels: a policy that runs
  /// flat out for eleven minutes and then stops is not "55 % busy", it is pegged
  /// for eleven minutes. It is also the only figure that does not move when the
  /// idle tail is made longer or shorter.
  ///
  /// It reads slightly HIGH by construction and cannot reach the steady-state
  /// bound: the window ends at the last rebuild's completion, so it contains `n`
  /// rebuilds but only `n - 1` cooldowns, giving `n / (n + 4(n-1))` — 25 % at
  /// n=4, 20 % as n grows. The exact policy invariant is asserted directly on the
  /// gaps instead (see 'every gap between rebuilds…'); this is for reporting.
  double get activeDuty {
    if (_load.starts.isEmpty || _load.ends.isEmpty) return 0;
    final span = _load.ends.last - _load.starts.first;
    return span <= 0 ? 1 : busyMs / span;
  }

  /// The idle gap the policy left between each rebuild finishing and the next
  /// starting — what the cooldown is supposed to enforce.
  List<int> get gaps => [
        for (var i = 1; i < _load.starts.length; i++)
          _load.starts[i] - _load.ends[i - 1],
      ];

  @override
  String toString() => 'rebuilds=$rebuilds busy=${busyMs ~/ 1000}s '
      'activeDuty=${(activeDuty * 100).toStringAsFixed(0)}% '
      'windowDuty=${(duty * 100).toStringAsFixed(0)}% '
      'firstUpdate=${firstAtMs == null ? "never" : "${firstAtMs! ~/ 1000}s"}';
}

Future<_Result> _runOld({
  required int loadMs,
  required int gapMs,
  required int offloadMs,
  required int tailMs,
}) async {
  final sim = _Sim();
  final load = _Load(sim, loadMs);
  final policy = _OldPolicy(sim, load.call);
  for (var t = 0; t <= offloadMs; t += gapMs) {
    await sim.advanceTo(t);
    policy.tick();
  }
  await sim.advanceTo(offloadMs + tailMs);
  return _Result(load, offloadMs + tailMs);
}

Future<_Result> _runNew({
  required int loadMs,
  required int gapMs,
  required int offloadMs,
  required int tailMs,
}) async {
  final sim = _Sim();
  final load = _Load(sim, loadMs);
  final s = LiveReloadScheduler(
    load: load.call,
    clock: sim.clock,
    timerFactory: sim.timer,
  );
  for (var t = 0; t <= offloadMs; t += gapMs) {
    await sim.advanceTo(t);
    s.request();
  }
  await sim.advanceTo(offloadMs + tailMs);
  s.dispose();
  return _Result(load, offloadMs + tailMs);
}

void main() {
  // A 44 s rebuild is the measured 90-day cost (19eb1b2a). A 10-minute offload is
  // an ordinary overnight catch-up. The tail is the quiet time after the last row
  // lands, long enough for any trailing rebuild to run.
  const load90d = 44000;
  const offload = 10 * 60 * 1000;
  const tail = 10 * 60 * 1000;

  group('the thrash regime — writes land further apart than the settle window', () {
    // Any gap over 2 s lets the old debounce fire DURING a rebuild, which latches
    // `pending`, which re-runs the instant the rebuild ends. It re-latches every
    // cycle, so the store is re-read end-to-end, continuously.
    const gap = 3000;

    test('BEFORE: the old policy runs rebuilds back-to-back at ~100% duty',
        () async {
      final r = await _runOld(
          loadMs: load90d, gapMs: gap, offloadMs: offload, tailMs: tail);
      // ignore: avoid_print
      print('thrash BEFORE: $r');
      expect(r.activeDuty, greaterThan(0.99),
          reason: 'every second from the first rebuild to the last is spent '
              'inside one — there is no gap between them at all');
      // 15 whole-store re-reads to service ONE offload, and 660 s of work to
      // cover a 600 s sync: the policy cannot even keep up with the writes, so it
      // runs over the end of the sync still re-reading.
      expect(r.rebuilds, greaterThanOrEqualTo(13));
      expect(r.busyMs, greaterThan(offload));
    });

    test('AFTER: duty is capped near 1/(1+dutyFactor) and rebuilds collapse',
        () async {
      final r = await _runNew(
          loadMs: load90d, gapMs: gap, offloadMs: offload, tailMs: tail);
      // ignore: avoid_print
      print('thrash AFTER:  $r');
      expect(r.activeDuty, lessThanOrEqualTo(0.25),
          reason: 'the 1/(1+dutyFactor) = 20% steady-state bound, read over a '
              'window that holds one fewer cooldown than rebuilds');
      expect(r.rebuilds, lessThanOrEqualTo(4));
      // Still shows the user something early rather than sitting on it.
      expect(r.firstAtMs, isNotNull);
      expect(r.firstAtMs, lessThanOrEqualTo(15000));
    });
  });

  group('the starvation regime — writes land closer together than the settle '
      'window', () {
    // The old debounce cancels and re-arms on every tick, so a burst that never
    // pauses for 2 s defers the rebuild until the sync is over.
    const gap = 500;

    test('BEFORE: nothing appears until the offload ends', () async {
      final r = await _runOld(
          loadMs: load90d, gapMs: gap, offloadMs: offload, tailMs: tail);
      // ignore: avoid_print
      print('starve BEFORE: $r');
      expect(r.firstAtMs, greaterThanOrEqualTo(offload),
          reason: 'the debounce never fires while the writes keep coming');
    });

    test('AFTER: maxWait serves the first rebuild during the offload', () async {
      final r = await _runNew(
          loadMs: load90d, gapMs: gap, offloadMs: offload, tailMs: tail);
      // ignore: avoid_print
      print('starve AFTER:  $r');
      expect(r.firstAtMs, lessThanOrEqualTo(15000));
      expect(r.activeDuty, lessThanOrEqualTo(0.25));
      expect(r.rebuilds, greaterThan(1),
          reason: 'data keeps arriving through the sync, just metered');
    });
  });

  test('the cooldown scales with the measured cost — a cheap store stays snappy',
      () async {
    // The same policy, the same timeline, only the rebuild cost differs. This is
    // the property no fixed constant has: a 1-day store (652 ms) must keep feeling
    // live while a 90-day store (44 s) gets left alone for minutes.
    for (final (label, cost) in [('1d', 652), ('7d', 3494), ('90d', 44230)]) {
      final r = await _runNew(
          loadMs: cost, gapMs: 3000, offloadMs: offload, tailMs: tail);
      // ignore: avoid_print
      print('scaling $label (load=${cost}ms): $r cooldown=~${(cost * 4) ~/ 1000}s');
      expect(r.activeDuty, lessThanOrEqualTo(0.25),
          reason: '$label must respect the duty bound');
      for (final g in r.gaps) {
        expect(g, greaterThanOrEqualTo(cost * 4),
            reason: '$label left only ${g}ms idle after a ${cost}ms rebuild');
      }
    }
    // A cheap store rebuilds far more often than an expensive one over the same
    // window — the point of tying the cooldown to the cost.
    final cheap = await _runNew(
        loadMs: 652, gapMs: 3000, offloadMs: offload, tailMs: tail);
    final dear = await _runNew(
        loadMs: 44230, gapMs: 3000, offloadMs: offload, tailMs: tail);
    expect(cheap.rebuilds, greaterThan(dear.rebuilds * 5));
  });

  test('the final state is always rebuilt — the last write is never dropped',
      () async {
    // The metering may DELAY a rebuild but must never lose the last one, or the
    // store and the UI end the sync disagreeing.
    for (final gap in [500, 3000, 30000]) {
      final sim = _Sim();
      final load = _Load(sim, 44000);
      final s = LiveReloadScheduler(
          load: load.call, clock: sim.clock, timerFactory: sim.timer);
      for (var t = 0; t <= 60000; t += gap) {
        await sim.advanceTo(t);
        s.request();
      }
      final beforeTail = load.starts.length;
      await sim.advanceTo(20 * 60 * 1000);
      s.dispose();
      expect(load.starts.length, greaterThan(0), reason: 'gap=$gap ran nothing');
      // A rebuild must START after the last write, so it observes every row.
      expect(load.starts.last, greaterThanOrEqualTo(60000),
          reason: 'gap=$gap: the last write was never picked up '
              '(started $beforeTail rebuilds, last at ${load.starts.last}ms)');
    }
  });

  test('a user-initiated rebuild bypasses the cooldown', () async {
    // Switching analysis engine / importing a backup is a person waiting on THIS
    // rebuild. Making them sit out a 3-minute cooldown would trade the overheating
    // for a UI that looks broken.
    final sim = _Sim();
    final load = _Load(sim, 44000);
    final s = LiveReloadScheduler(
        load: load.call, clock: sim.clock, timerFactory: sim.timer);

    s.request(); // strap write
    await sim.advanceTo(60000); // first rebuild ran; cooldown now ~176 s
    expect(load.starts.length, 1);

    s.request(immediate: true); // user switches engine
    await sim.advanceTo(61000);
    expect(load.starts.length, 2,
        reason: 'a user action must not wait out the cooldown');
    expect(load.starts.last, lessThanOrEqualTo(61000));
    s.dispose();
  });

  test('a user-initiated rebuild still waits for an in-flight one (single flight)',
      () async {
    final sim = _Sim();
    final load = _Load(sim, 44000);
    final s = LiveReloadScheduler(
        load: load.call, clock: sim.clock, timerFactory: sim.timer);

    s.request();
    await sim.advanceTo(3000); // rebuild #1 is now in flight (started at 2000)
    expect(load.starts.length, 1);
    s.request(immediate: true);
    await sim.advanceTo(20000); // still inside rebuild #1 (ends at 46000)
    expect(load.starts.length, 1, reason: 'two full loads must never overlap');
    await sim.advanceTo(50000);
    expect(load.starts.length, 2, reason: 'and it runs as soon as #1 is done');
    s.dispose();
  });

  test('an idle app does no work at all', () async {
    final sim = _Sim();
    final load = _Load(sim, 44000);
    final s = LiveReloadScheduler(
        load: load.call, clock: sim.clock, timerFactory: sim.timer);
    await sim.advanceTo(60 * 60 * 1000);
    expect(load.starts, isEmpty);
    s.dispose();
  });
}
