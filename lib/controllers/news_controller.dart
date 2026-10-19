import 'package:get/get.dart';

import 'package:emaskuid/data/api/api_client.dart';
import 'package:emaskuid/data/models/models.dart';

/// News list + article detail.
class NewsController extends GetxController {
  NewsController(this._api);

  final ApiClient _api;

  final RxList<NewsItem> items = <NewsItem>[].obs;
  final RxBool loading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (loading.value) return;
    loading.value = true;
    error.value = '';
    try {
      items.assignAll(await _api.news());
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<NewsDetail> detail(String url) => _api.newsDetail(url);
}
