import 'package:flutter/material.dart';

import 'package:noop/shared/widgets/coming_soon.dart';
import 'package:noop/shared/widgets/scaffold.dart';
import 'package:noop/core/theme/metrics.dart';

// WHOOP-style purple hero that fades into the app's dark base — the Journal's
// signature surface (an explicitly-allowed gradient exception).
const _purpleTop = Color(0xFF4B2E86);
const _purpleMid = Color(0xFF3A2A63);

/// The WHOOP-style logbook. There's no real journal capture source yet, so the
/// screen shows an on-brand "coming soon" state over its purple hero rather than
/// a fabricated set of behaviours.
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_purpleTop, _purpleMid, Color(0xFF15161C)],
            stops: [0, 0.28, 0.62],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              const Expanded(
                child: ComingSoonView(
                  icon: Icons.edit_note_rounded,
                  title: 'Logbook',
                  message:
                      'Journaling your daily behaviours is on the way. Soon '
                      "you'll log what affects your recovery and see how each "
                      'habit moves your scores.',
                  onColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Minimal centred header: the canonical NoopBackButton (auto-shown when the
  // route can pop — Journal is always pushed) plus a mirrored trailing slot so
  // the white title stays optically centred. We keep the white title here
  // rather than use CenteredHeader because its Palette.textPrimary title/icon
  // colours flip with the theme and would clash on this fixed purple hero.
  Widget _header(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: canPop
                ? NoopBackButton(onTap: () => Navigator.of(context).maybePop())
                : null,
          ),
          Expanded(
            child: Center(
              child: Text('LOGBOOK',
                  style: NoopType.overline.copyWith(
                      color: Colors.white,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          // Mirrors the 40×40 back-button slot so the title stays centred.
          const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }
}
