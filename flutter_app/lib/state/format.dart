import 'package:intl/intl.dart';

/// Display formatting helpers shared across screens.
class Fmt {
  Fmt._();

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
