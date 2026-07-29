import 'package:intl/intl.dart';

class Formatters {
  static final _currency = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  static final _date = DateFormat('dd/MM/yyyy', 'fr_FR');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
  static final _shortDate = DateFormat('dd MMM yyyy', 'fr_FR');

  static String currency(num? amount) {
    if (amount == null) return '— FCFA';
    return _currency.format(amount);
  }

  static String date(DateTime? dt) {
    if (dt == null) return '—';
    return _date.format(dt);
  }

  static String dateTime(DateTime? dt) {
    if (dt == null) return '—';
    return _dateTime.format(dt);
  }

  static String shortDate(DateTime? dt) {
    if (dt == null) return '—';
    return _shortDate.format(dt);
  }

  /// Ex: "il y a 2 heures"
  static String timeAgo(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "il y a ${diff.inHours}h";
    if (diff.inDays < 7) return "il y a ${diff.inDays} jours";
    return date(dt);
  }
}
