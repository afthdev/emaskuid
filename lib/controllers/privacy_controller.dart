import 'package:get/get.dart';

import 'package:emaskuid/data/local/prefs_store.dart';

/// Controls whether the user's own money figures are shown or masked.
/// Public market prices are never affected — only savings-side nominals.
class PrivacyController extends GetxController {
  PrivacyController(this._prefs);

  final PrefsStore _prefs;

  final RxBool hidden = false.obs;

  @override
  void onInit() {
    hidden.value = _prefs.hideNominal;
    super.onInit();
  }

  void toggle() {
    hidden.value = !hidden.value;
    _prefs.setHideNominal(hidden.value);
  }
}
