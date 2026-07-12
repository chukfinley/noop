import 'package:intl/intl.dart';

import 'package:noop/core/state/prefs.dart' show EffortScale;

/// Display formatting helpers shared across screens.
class Fmt {
  Fmt._();

  /// Format an Effort/day-strain value (always computed on the internal 0..100
  /// scale) for display under the user's chosen [EffortScale] (ryanbr #45).
  /// The 0..21 WHOOP scale is linearly compressed and shown with one decimal
  /// (matching WHOOP); 0..100 is shown as a whole number. Band/state thresholds
  /// stay on the internal 0..100 value, so only the number changes.
  static String effort(double v0to100, EffortScale scale) => scale == EffortScale.whoop
      ? (v0to100 / 100.0 * 21.0).toStringAsFixed(1)
      : v0to100.round().toString();

  /// Celsius → the user's unit. Pass an absolute temperature in °C.
  static String temp(double celsius, {required bool fahrenheit, int digits = 0}) {
    final v = fahrenheit ? celsius * 9 / 5 + 32 : celsius;
    return '${v.toStringAsFixed(digits)}°${fahrenheit ? 'F' : 'C'}';
  }

  static String hm(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  static String hoursDecimal(Duration d) =>
      (d.inMinutes / 60).toStringAsFixed(1);

  static String clock(DateTime t) => DateFormat.Hm().format(t);

  static String dayTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat.EEEE().format(date);
  }

  static String longDate(DateTime date) => DateFormat('EEEE, d MMMM').format(date);
  static String shortDate(DateTime date) => DateFormat('d MMM').format(date);

  static String signed(double v, {int digits = 0}) =>
      (v >= 0 ? '+' : '') + v.toStringAsFixed(digits);

  static String km(double km) => '${km.toStringAsFixed(1)} km';

  static String intComma(int n) => NumberFormat.decimalPattern().format(n);
}
