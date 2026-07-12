import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/protocol/streams.dart';

/// Faithful Dart port of `SkinTempConversionTest.kt`.
///
/// Device-family-aware skin-temp raw→°C conversion (#938). The historical `skin_temp_raw` register is
/// on DIFFERENT scales per family: a CENTIDEGREE value on the 5/MG v18 (@73) but a RAW ADC on the
/// WHOOP 4.0 v24 (@72). A single family-blind `raw/100` sent every 4.0 night ~8 °C low, below the
/// 28 °C worn gate, so skin temp + the illness signal vanished (issue #938).
void main() {
  // ── WHOOP 5/MG (unchanged: raw/100 centidegrees) ────────────────────────

  test('whoop5IsUnchangedCentidegrees', () {
    expect(skinTempCelsius(3057, DeviceFamily.whoop5), closeTo(30.57, 1e-9));
    expect(skinTempCelsius(2247, DeviceFamily.whoop5), closeTo(22.47, 1e-9));
    expect(skinTempCelsius(3400, DeviceFamily.whoop5), closeTo(34.0, 1e-9));
  });

  // ── WHOOP 4.0 v24 (raw ADC map) ─────────────────────────────────────────

  test('whoop4WornBaselineLandsInPlausibleBand', () {
    for (final raw in <int>[826, 830, 845, 859, 865]) {
      final c = skinTempCelsius(raw, DeviceFamily.whoop4);
      expect(c, greaterThanOrEqualTo(28.0),
          reason: 'worn 4.0 raw $raw → $c °C must clear the 28 °C worn gate');
      expect(c, lessThanOrEqualTo(42.0),
          reason: 'worn 4.0 raw $raw → $c °C must stay under the 42 °C worn ceiling');
    }
    expect(skinTempCelsius(826, DeviceFamily.whoop4), closeTo(33.0, 1e-9));
  });

  test('whoop4NoContactFloorIsBelowWornGate', () {
    for (final raw in <int>[506, 514, 520]) {
      expect(skinTempCelsius(raw, DeviceFamily.whoop4), lessThan(28.0),
          reason: '4.0 no-contact floor raw $raw must fall below the worn gate');
    }
  });

  test('whoop4AndWhoop5DifferForTheSameRaw', () {
    expect(
      (skinTempCelsius(826, DeviceFamily.whoop4) -
              skinTempCelsius(826, DeviceFamily.whoop5))
          .abs(),
      greaterThan(1e-6),
    );
  });

  test('whoop4SyntheticFixtureRawIsPlausible', () {
    final c = skinTempCelsius(900, DeviceFamily.whoop4);
    expect(c, greaterThan(28.0));
    expect(c, lessThan(42.0));
  });
}
