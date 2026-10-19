import 'package:intl/intl.dart';

/// All user-facing value formatting lives here so screens stay dumb.
class Fmt {
  Fmt._();

  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  static final NumberFormat _rupiahCompact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 1,
  );
  static final NumberFormat _decimal = NumberFormat.decimalPattern('id_ID');
  static final NumberFormat _percent = NumberFormat.decimalPattern('id_ID')
    ..maximumFractionDigits = 2;

  /// Groups digits as the user types: "23450000" -> "23.450.000".
  /// Allows one comma with up to 2 decimals: "23450000,5" -> "23.450.000,5".
  static String formatNumberInput(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9,]'), '');
    if (cleaned.isEmpty) return '';
    final parts = cleaned.split(',');
    final intPart = parts.first;
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    if (parts.length > 1) {
      final dec = parts[1].length > 2 ? parts[1].substring(0, 2) : parts[1];
      return '$buffer,$dec';
    }
    return buffer.toString();
  }

  /// Parses a formatted number ("24.500.000" / "24.500.000,50") into a double.
  static double parseNumberInput(String text) {
    final cleaned = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  /// Formats a known value for an input field: 24500000 -> "24.500.000".
  static String formatNumberValue(num value) {
    if (value == value.roundToDouble()) {
      return formatNumberInput(value.toInt().toString());
    }
    return formatNumberInput(value.toStringAsFixed(2).replaceAll('.', ','));
  }

  static String rupiah(num? value) {
    if (value == null) return '-';
    return _rupiah.format(value);
  }

  static String rupiahCompact(num? value) {
    if (value == null) return '-';
    if (value.abs() < 1000000) return _rupiah.format(value);
    return _rupiahCompact.format(value);
  }

  /// Weight in grams, without trailing ".0" (e.g. 0,5 gr / 10 gr).
  static String gram(num? value) {
    if (value == null) return '-';
    final text = _decimal.format(value);
    return '$text gr';
  }

  /// Signed rupiah, e.g. "+Rp10.000" / "-Rp10.000".
  static String signedRupiah(num? value) {
    if (value == null) return '-';
    final sign = value > 0 ? '+' : '';
    return '$sign${_rupiah.format(value)}';
  }

  static String percent(num? value) {
    if (value == null) return '-';
    final sign = value > 0 ? '+' : '';
    return '$sign${_percent.format(value)}%';
  }

  static String date(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('d MMM yyyy', 'id_ID').format(value);
  }

  static String dateShort(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('d MMM', 'id_ID').format(value);
  }

  static String dateTime(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(value);
  }

  /// Parses both `2026-10-15` and full ISO timestamps.
  static DateTime? parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  /// Makes rows of raw `materialType` strings readable.
  static String shortMaterialType(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Emas';
    final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.length <= 42) return cleaned;
    return '${cleaned.substring(0, 39)}...';
  }
}
