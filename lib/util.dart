import 'package:shamsi_date/shamsi_date.dart';

const monthNames = [
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
  'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
];

String two(int n) => n.toString().padLeft(2, '0');

String jDate(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return '${j.year}/${two(j.month)}/${two(j.day)}';
}

String jDateStr(String? iso) => iso == null ? '' : jDate(DateTime.parse(iso));

String minutesText(int sec) => '${(sec / 60).ceil()} دقیقه';
