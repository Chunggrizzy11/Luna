import 'package:intl/intl.dart';

abstract final class ApiDate {
  static final DateFormat _date = DateFormat('yyyy-MM-dd');
  static final DateFormat _month = DateFormat('yyyy-MM');

  static String date(DateTime value) => _date.format(value);
  static String month(DateTime value) => _month.format(value);
  static DateTime parse(String value) => DateTime.parse(value);
}
