import 'package:intl/intl.dart';

class Fmt {
  static final _inr = NumberFormat.currency(
      locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _inr2 = NumberFormat.currency(
      locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  static final _compact = NumberFormat.compactCurrency(
      locale: 'en_IN', symbol: '₹', decimalDigits: 1);
  static final _date = DateFormat('dd MMM yyyy, hh:mm a');

  static String money(num v) => _inr.format(v);
  static String money2(num v) => _inr2.format(v);
  static String compactMoney(num v) => _compact.format(v);
  static String date(DateTime d) => _date.format(d);
  static String num0(num v) => NumberFormat.decimalPattern('en_IN').format(v);
}
