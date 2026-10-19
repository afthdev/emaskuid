import 'package:get/get.dart';

import 'package:emaskuid/data/local/prefs_store.dart';

/// Persisted "my toko" + watchlist selection.
class WatchlistController extends GetxController {
  WatchlistController(this._prefs);

  final PrefsStore _prefs;

  final RxString primary = ''.obs;
  final RxList<String> watchlist = <String>[].obs;

  @override
  void onInit() {
    primary.value = _prefs.primaryVendor ?? '';
    watchlist.assignAll(_prefs.watchlist);
    super.onInit();
  }

  bool isWatched(String source) => watchlist.contains(source);

  Future<void> setPrimary(String source) async {
    primary.value = source;
    await _prefs.setPrimaryVendor(source);
    if (!isWatched(source)) await toggleWatch(source);
  }

  Future<void> toggleWatch(String source) async {
    if (isWatched(source)) {
      watchlist.remove(source);
      if (primary.value == source) primary.value = '';
    } else {
      watchlist.add(source);
    }
    await _prefs.setWatchlist(watchlist.toList());
    if (primary.value.isEmpty) await _prefs.setPrimaryVendor(null);
  }
}
