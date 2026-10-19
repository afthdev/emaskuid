import 'package:emaskuid/controllers/privacy_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// App-bar eye button that toggles masking of the savings nominals.
class PrivacyToggleButton extends StatelessWidget {
  const PrivacyToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final privacy = Get.find<PrivacyController>();
      final hidden = privacy.hidden.value;
      return IconButton(
        tooltip: hidden ? 'Tampilkan nominal' : 'Sembunyikan nominal',
        onPressed: privacy.toggle,
        icon: Icon(
          hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        ),
      );
    });
  }
}
