import 'package:emaskuid/core/utils/formatters.dart';
import 'package:flutter/services.dart';

/// Live thousands-separator formatting for numeric currency inputs.
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = Fmt.formatNumberInput(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
