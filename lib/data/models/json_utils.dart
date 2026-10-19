/// Small coercion helpers for the loosely-typed JSON returned by the API.
double asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

double? asDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

/// Gold prices of 0 mean "not offered by this toko", not "free".
double? asPositiveOrNull(dynamic value) {
  final parsed = asDoubleOrNull(value);
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}

String asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}
