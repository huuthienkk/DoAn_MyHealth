import 'package:intl/intl.dart';

String formatDateShort(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);
String formatDateTime(DateTime dt) => DateFormat('dd/MM/yyyy HH:mm').format(dt);

DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
