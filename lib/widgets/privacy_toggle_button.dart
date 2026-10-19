import 'package:emaskuid/controllers/privacy_controller.dart';
import 'package:emaskuid/widgets/sem_id.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// App-bar eye button that toggles masking of the savings nominals.
class PrivacyToggleButton extends StatelessWidget {
  const PrivacyToggleButton({super.key, required this.testId});

  /// Automation id, so each screen's instance stays distinguishable.
  final String testId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final privacy = Get.find<PrivacyController>();
      final hidden = privacy.hidden.value;
      return SemId(
        testId,
        child: IconButton(
          tooltip: hidden ? 'Tampilkan nominal' : 'Sembunyikan nominal',
          onPressed: privacy.toggle,
          icon: Icon(
            hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          ),
        ),
      );
    });
  }
}
