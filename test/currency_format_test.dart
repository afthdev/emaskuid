import 'package:emaskuid/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fmt number input', () {
    test('groups thousands while typing', () {
      expect(Fmt.formatNumberInput('23450000'), '23.450.000');
      expect(Fmt.formatNumberInput('1000'), '1.000');
      expect(Fmt.formatNumberInput('999'), '999');
    });

    test('keeps one comma with up to two decimals', () {
      expect(Fmt.formatNumberInput('23450000,5'), '23.450.000,5');
      expect(Fmt.formatNumberInput('23450000,50'), '23.450.000,50');
      expect(Fmt.formatNumberInput('23450000,509'), '23.450.000,50');
    });

    test('ignores non-numeric characters', () {
      expect(Fmt.formatNumberInput('Rp 24.500.000'), '24.500.000');
      expect(Fmt.formatNumberInput(''), '');
    });

    test('parses grouped values back to numbers', () {
      expect(Fmt.parseNumberInput('23.450.000'), 23450000);
      expect(Fmt.parseNumberInput('23.450.000,50'), 23450000.5);
    });

    test('formats a known value for the field', () {
      expect(Fmt.formatNumberValue(24500000), '24.500.000');
      expect(Fmt.formatNumberValue(24500000.5), '24.500.000,50');
    });
  });
}
