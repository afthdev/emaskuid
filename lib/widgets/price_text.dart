import 'package:emaskuid/controllers/privacy_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A price that never wraps: it scales down to fit on one line.
/// When [sensitive] is true it is masked while the privacy toggle is on.
class PriceText extends StatelessWidget {
  const PriceText(
    this.value, {
    super.key,
    this.style,
    this.color,
    this.align = Alignment.centerLeft,
    this.sensitive = false,
  });

  static const String masked = '••••••';

  final String value;
  final TextStyle? style;
  final Color? color;
  final Alignment align;
  final bool sensitive;

  @override
  Widget build(BuildContext context) {
    if (!sensitive) return _render(value);
    return Obx(() {
      final hidden =
          Get.isRegistered<PrivacyController>() &&
          Get.find<PrivacyController>().hidden.value;
      return _render(hidden ? masked : value);
    });
  }

  Widget _render(String text) {
    final base =
        style ?? const TextStyle(fontWeight: FontWeight.w800, fontSize: 15);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: align,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: color == null ? base : base.copyWith(color: color),
      ),
    );
  }
}
