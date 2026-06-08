import 'dart:math';
import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  static final _dbDateFormat = DateFormat('yyyy-MM-dd');
  static final _displayDateFormat = DateFormat('dd-MM-yyyy');
  static final _displayDateTimeFormat = DateFormat('dd-MM-yyyy HH:mm');

  static String currency(int amount) => _currency.format(amount);
  static String dbDate(DateTime date) => _dbDateFormat.format(date);
  static String displayDate(String dbDate) {
    try {
      return _displayDateFormat.format(DateTime.parse(dbDate));
    } catch (_) {
      return dbDate;
    }
  }
  static String displayDateTime(DateTime date) => _displayDateTimeFormat.format(date);
  static String displayDateOnly(DateTime date) => _displayDateFormat.format(date);
}

class IdGenerator {
  IdGenerator._();
  static final _random = Random();
  static String generate(String prefix) {
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(99999)}';
  }
}

class Validators {
  Validators._();

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telepon wajib diisi';
    }
    if (!RegExp(r'^[0-9+\\-\\s]+$').hasMatch(value)) {
      return 'Format telepon tidak valid';
    }
    return null;
  }

  static String? positiveInt(String? value, String fieldName, {int? max}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    final n = int.tryParse(value.trim());
    if (n == null || n < 0) {
      return '$fieldName harus angka positif';
    }
    if (max != null && n > max) {
      return '$fieldName maksimal $max';
    }
    return null;
  }

  static String? dateRange(DateTime checkIn, DateTime checkOut) {
    if (!checkOut.isAfter(checkIn)) {
      return 'Check-out harus setelah check-in';
    }
    return null;
  }
}