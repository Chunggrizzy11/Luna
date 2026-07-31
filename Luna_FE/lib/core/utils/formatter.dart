import 'package:intl/intl.dart';

abstract final class Formatter {
  static final _date = DateFormat('dd/MM/yyyy', 'vi');
  static final _integer = NumberFormat.decimalPattern('vi');

  static String date(DateTime value) => _date.format(value);

  static String integer(num value) => _integer.format(value);
}
