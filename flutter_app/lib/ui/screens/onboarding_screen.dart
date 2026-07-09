import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../components/backgrounds.dart';
import '../components/common.dart';
import '../components/liquid.dart';
import '../theme/metrics.dart';
import '../theme/palette.dart';

/// First-run intro carousel — a paged tour with per-slide illustration + copy
/// and a "Get Started" CTA on the last slide. Mirrors Plane's PageView onboarding.
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(duration: Motion.durationStandard, curve: Motion.easeInOut);
    } else {
      ref.read(onboardedProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    return Scaffold(
      body: ScenicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => ref.read(onboardedProvider.notifier).state = true,
                  child: Text('Skip',
                      style: NoopType.subhead.copyWith(color: Palette.textTertiary)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _slides.length,
                  itemBuilder: (context, i) => _SlideView(_slides[i]),
                ),
              ),
              _Dots(count: _slides.length, index: _page),
              const SizedBox(height: Metrics.space24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Metrics.screenPadding),
                child: SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NoopButton(last ? 'Get started' : 'Next', onPressed: _next),
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
