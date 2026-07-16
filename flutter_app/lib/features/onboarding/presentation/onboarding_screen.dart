import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/ble/permissions.dart';
import 'package:noop/core/ble/transport/whoop_ble_client.dart';
import 'package:noop/core/ble/transport/whoop_providers.dart';
import 'package:noop/core/state/prefs.dart';
import 'package:noop/core/state/providers.dart';
import 'package:noop/shared/widgets/backgrounds.dart';
import 'package:noop/shared/widgets/common.dart';
import 'package:noop/shared/widgets/liquid.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

/// First-run intro carousel — a paged tour with per-slide illustration + copy, closing on a
/// "Find your strap" step where the user PICKS their band, then a "Get started" CTA.
///
/// Why the pick step exists (reported against the tanarchytan/noop fork): first pairing used to be
/// "tap Connect and let a scan adopt whatever answers first". A scan hit is not a choice — a
/// partner's, a flatmate's or a stranger's WHOOP advertises exactly the same, and whichever wins the
/// race gets PERSISTED as the paired strap, silently re-pointing every later sync at the wrong band.
/// Onboarding is precisely where that misfires, because it is the one moment nothing is remembered
/// yet, so there is no correct band for a scan to prefer. The strap list is short and the user knows
/// which one is on their wrist; asking is cheap and guessing is not.
///
/// Skippable on purpose: a user without their strap to hand must not be trapped in onboarding. Skip
/// leaves nothing remembered, and (since [WhoopBleClient.resolveAutoConnect] refuses to adopt an
/// unknown band) no automatic path will quietly pair for them later — they pair from
/// Settings → Scan for straps, deliberately, exactly as here.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide('Recovery, decoded', 'Every morning, a single Charge score from your HRV, resting heart rate and sleep — so you know how hard to push today.', DomainTheme.charge, 0.72),
    _Slide('Every night, measured', 'Full hypnograms, sleep debt and a nightly Rest score. See exactly how your night rebuilt you.', DomainTheme.rest, 0.86),
    _Slide('Effort that counts', 'Continuous strain from your heart rate turns every workout — and every busy day — into one honest Effort number.', DomainTheme.effort, 0.4),
    _Slide('Your body, live', 'HRV, resting HR, respiratory rate, skin temp and blood oxygen — streamed from your strap, all in one place.', DomainTheme.charge, 0.6),
  ];

  /// The pick-your-band step sits after the last slide, so the page count is one past the slides.
  static int get _pairPage => _slides.length;
  static int get _pageCount => _slides.length + 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _finishing = false;

  Future<void> _complete() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    // Ask for the grants the app actually needs, right here in onboarding: BLE
    // (scan + connect) so the strap can be found, and notifications so background
    // sync can show its status. Both no-op off mobile and never block finishing —
    // a denied grant just means the user re-grants later from Settings.
    try {
      await ensureBlePermissions();
      await ensureNotificationPermission();
      await ensureBatteryOptimizationExemption();
    } catch (_) {}
    Prefs.instance.setOnboarded(true);
    if (!mounted) return;
    ref.read(onboardedProvider.notifier).state = true;
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _controller.nextPage(duration: Motion.durationStandard, curve: Motion.easeInOut);
    } else {
      _complete();
    }
  }

  /// The user picked their band: connect to THAT strap by id ([WhoopBleClient.connectToStrap]), never
  /// a scan-order guess. A successful connect is what persists it as the paired strap, so onboarding
  /// finishes either way — a strap that fails to answer must not trap the user on this step, and the
  /// device screen surfaces the transport's own error honestly once they are inside the app.
  Future<void> _pick(DiscoveredStrap strap) async {
    await ref.read(whoopBleClientProvider).connectToStrap(strap);
    if (!mounted) return;
    await _complete();
  }

  @override
  Widget build(BuildContext context) {
    final onPair = _page == _pairPage;
    return Scaffold(
      body: ScenicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _complete,
                  child: Text('Skip',
                      style: NoopType.subhead.copyWith(color: Palette.textTertiary)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _pageCount,
                  itemBuilder: (context, i) => i == _pairPage
                      // `active` gates the scan on the step actually being SHOWN. PageView builds
                      // neighbours during a swipe, and watching the scan provider is what starts the
                      // radio + raises the permission dialog — both would otherwise fire behind the
                      // previous slide, mid-gesture, before the user has been told what we're doing.
                      ? _PairStep(active: onPair, onPick: _pick)
                      : _SlideView(_slides[i]),
                ),
              ),
              _Dots(count: _pageCount, index: _page),
              const SizedBox(height: Metrics.space24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Metrics.screenPadding),
                child: SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // On the pair step the primary button must not imply pairing happened — the
                      // strap is paired by TAPPING it in the list, not by advancing. "Skip for now"
                      // says what the button really does: finish onboarding with nothing paired.
                      NoopButton(onPair ? 'Skip for now' : 'Next', onPressed: _next),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Metrics.space24),
            ],
          ),
        ),
      ),
    );
  }
}

/// The pick-your-band step: watching [strapScanProvider] starts a discovery scan of both WHOOP
/// families and lists what it hears, strongest signal first, for the user to tap.
///
/// Radio-free by construction off-device: `discoverStraps` emits an empty list on
/// desktop/web/tests without touching the plugin, so this renders its empty state and the widget
/// tests stay inert. It also owns the permission request (the transport's gate runs inside
/// `discoverStraps`), so any refusal surfaces as that gate's honest guidance rather than a silent
/// list that never fills — the failure mode this whole step exists to avoid.
class _PairStep extends ConsumerWidget {
  final bool active;
  final Future<void> Function(DiscoveredStrap) onPick;
  const _PairStep({required this.active, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Not shown yet → don't watch, don't scan, don't prompt.
    final straps = active
        ? (ref.watch(strapScanProvider).value ?? const <DiscoveredStrap>[])
        : const <DiscoveredStrap>[];
    // The transport's own last error (permission blocked, adapter off, scan failed). Read, not
    // watched — it is plain mutable state on the client, and this rebuilds on every scan tick anyway.
    final error = active ? ref.read(whoopBleClientProvider).lastError : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Find your strap',
              textAlign: TextAlign.center,
              style: NoopType.title1.copyWith(color: Palette.textPrimary)),
          const SizedBox(height: Metrics.space12),
          Text(
            'Tap your band to pair it. NOOP never picks one for you — if someone '
            'else’s WHOOP is nearby, it looks exactly the same from here.',
            textAlign: TextAlign.center,
            style: NoopType.body.copyWith(color: Palette.textSecondary, height: 1.4),
          ),
          const SizedBox(height: Metrics.sectionGap),
          if (error != null)
            Text(error,
                textAlign: TextAlign.center,
                style: NoopType.footnote.copyWith(color: Palette.textTertiary))
          else if (straps.isEmpty)
            Column(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Palette.accent),
                ),
                const SizedBox(height: Metrics.space12),
                Text('Scanning nearby — keep your strap close.',
                    textAlign: TextAlign.center,
                    style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
              ],
            )
          else
            for (final strap in straps) ...[
              _StrapRow(strap: strap, onTap: () => onPick(strap)),
              const SizedBox(height: Metrics.space8),
            ],
        ],
      ),
    );
  }
}

/// One tappable discovered strap. Shows the signal strength alongside the name because that is the
/// only cue distinguishing two identically-named WHOOPs — the closer band is the one on your wrist.
class _StrapRow extends StatelessWidget {
  final DiscoveredStrap strap;
  final VoidCallback onTap;
  const _StrapRow({required this.strap, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Palette.fillRaised,
        borderRadius: BorderRadius.circular(Metrics.cornerLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Metrics.space14, vertical: Metrics.space12),
            child: Row(
              children: [
                Icon(Icons.watch_rounded, size: 20, color: Palette.accent),
                const SizedBox(width: Metrics.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strap.name,
                          style: NoopType.body.copyWith(
                              color: Palette.textPrimary,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('${strap.rssi} dBm',
                          style: NoopType.caption
                              .copyWith(color: Palette.textTertiary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Palette.textTertiary, size: 20),
              ],
            ),
          ),
        ),
      );
}

class _Slide {
  final String title;
  final String body;
  final DomainTheme domain;
  final double fraction;
  const _Slide(this.title, this.body, this.domain, this.fraction);
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView(this.slide);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LiquidVessel(
            fraction: slide.fraction,
            ramp: slide.domain.dataStops,
            size: 180,
            center: Text(slide.domain.label,
                style: NoopType.overline.copyWith(
                  color: Colors.white,
                  shadows: [const Shadow(color: Colors.black54, blurRadius: 6)],
                )),
          ),
          const SizedBox(height: Metrics.sectionGap),
          Text(slide.title,
              textAlign: TextAlign.center,
              style: NoopType.title1.copyWith(color: Palette.textPrimary)),
          const SizedBox(height: Metrics.space12),
          Text(slide.body,
              textAlign: TextAlign.center,
              style: NoopType.body.copyWith(color: Palette.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: Motion.durationStandard,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index ? Palette.accent : Palette.hairlineStrong,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
