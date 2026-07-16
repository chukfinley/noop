import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/bond/bond_refusal_give_up.dart';
import 'package:noop/core/ble/strap_log_pii.dart';

/// Port of upstream's `PiiRedactionTest.kt` (#445), plus the cases that are ours rather than theirs.
///
/// The contract: a strap log exists to be SHARED (the device screen copies it into a bug report), so
/// no line in it may carry the user's Bluetooth MAC or their WHOOP serial — while every line must
/// still carry the model names and protocol nouns that make the trace readable. Pure policy, no BLE
/// seam, so this needs no radio (the project rule forbids launching the app).
void main() {
  group('masks the identifiers', () {
    test('MAC keeps only the first and last octet', () {
      expect(
        redactStrapLogPii('HR-strap: connecting to A1:B2:C3:D4:E5:F6'),
        'HR-strap: connecting to A1:••:••:••:••:F6',
      );
    });

    test('the four identifying middle octets never survive, in any case form', () {
      for (final mac in ['00:11:22:33:44:55', 'AA:bb:CC:dd:EE:ff', 'de:ad:be:ef:12:34']) {
        final out = redactStrapLogPii('connecting to $mac now');
        expect(out.contains(mac), isFalse, reason: 'middle octets must be masked: $out');
      }
    });

    test('WHOOP serial is replaced wholesale', () {
      expect(
        redactStrapLogPii('Discovered WHOOP 4C1594026 (rssi -63)'),
        'Discovered WHOOP <serial> (rssi -63)',
      );
    });

    test('a MAC and a serial on ONE line are both masked', () {
      // Our "Strap found" + "Connecting to" lines are adjacent in a real trace; a line carrying both
      // must not have one scrubber's rewrite mask the other's match.
      final out = redactStrapLogPii('Strap found: WHOOP 4C1594026 at AA:BB:CC:DD:EE:FF');
      expect(out, 'Strap found: WHOOP <serial> at AA:••:••:••:••:FF');
    });
  });

  group('leaves the readable trace alone', () {
    test('dotted + mid-dot model names are not serials', () {
      // These are the names this log is FULL of. Scrubbing them would cost the trace the one fact it
      // most needs (which strap family we are talking to), so the digit-led 6+ run is load-bearing.
      for (final line in [
        'Auto-reconnecting to your saved WHOOP 4.0',
        'Paired band: WHOOP 5·MG',
        'WHOOP 5/MG: CLIENT_HELLO sent',
        'Scan: looking for a WHOOP 4 strap',
      ]) {
        expect(redactStrapLogPii(line), line, reason: 'model name must survive: $line');
      }
    });

    test('plain protocol lines pass through byte-identical', () {
      const line = 'Backfill: session ended — reason=HISTORY_COMPLETE';
      expect(redactStrapLogPii(line), line);
    });

    test('a clock time is not a MAC', () {
      // Three colon-separated groups, not six — the octet count is what keeps timestamps readable.
      const line = 'Strap alarm armed at 06:30:00 local';
      expect(redactStrapLogPii(line), line);
    });
  });

  group('composes with the opaqueId idiom rather than fighting it', () {
    test('an opaque bond token passes through untouched', () {
      // The connect line and the bond epitaph both name a strap by BondRefusalGiveUp.opaqueId. That
      // token is bare hex with no colons and no "WHOOP <digits>", so the scrubber must not rewrite it
      // — if it did, the two lines would stop agreeing on which strap they are about.
      final token = BondRefusalGiveUp.opaqueId('A1:B2:C3:D4:E5:F6');
      final line = 'Connecting to strap [$token] (whoop4)';
      expect(redactStrapLogPii(line), line);
    });

    test('the bond epitaph survives redaction intact', () {
      final line = BondRefusalGiveUp.epitaphLine(5, BondRefusalGiveUp.opaqueId('A1:B2:C3:D4:E5:F6'));
      // It says "the official WHOOP app" — "WHOOP " not followed by a digit, so the serial scrubber
      // must leave it alone.
      expect(redactStrapLogPii(line), line);
    });
  });

  group('is total', () {
    test('never throws, on any input', () {
      final nasty = [
        '',
        'no pii here',
        r'literal dollar $3 and ${0} and \1 in the text',
        r'AA:BB:CC:DD:EE:FF WHOOP 4C1594026 mixed $ \ ${',
        'x' * 20000,
        '00:11:22:33:44:55 ' * 500,
      ];
      for (final s in nasty) {
        // The contract is "returns a String, never throws" — assert it completes for every input.
        expect(() => redactStrapLogPii(s), returnsNormally, reason: 'threw on: ${s.length} chars');
      }
    });

    test(r'a literal $1 in the log text is not treated as a capture reference', () {
      // Upstream's #421/#453 crash was a replacement string parsed for $n. Dart takes groups from the
      // match object, so a dollar in the DATA must be inert — pin that it stays inert.
      expect(redactStrapLogPii(r'cost $1 at AA:BB:CC:DD:EE:FF'), r'cost $1 at AA:••:••:••:••:FF');
    });

    test('every MAC on a repeated line is masked, not just the first', () {
      final out = redactStrapLogPii('a AA:BB:CC:DD:EE:FF b 11:22:33:44:55:66');
      expect(out, 'a AA:••:••:••:••:FF b 11:••:••:••:••:66');
    });
  });
}
