import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:emaskuid/app/app.dart';
import 'package:emaskuid/controllers/news_controller.dart';
import 'package:emaskuid/controllers/price_controller.dart';
import 'package:emaskuid/controllers/privacy_controller.dart';
import 'package:emaskuid/controllers/transaction_controller.dart';
import 'package:emaskuid/controllers/watchlist_controller.dart';
import 'package:emaskuid/data/api/api_client.dart';
import 'package:emaskuid/data/local/local_database.dart';
import 'package:emaskuid/data/local/prefs_store.dart';
import 'package:emaskuid/data/repositories/transaction_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID');

  final api = ApiClient();
  final prefs = await PrefsStore.init();
  final database = await AppDatabase.open();

  // App-wide singletons.
  Get.put(api, permanent: true);
  Get.put(prefs, permanent: true);
  Get.put(TransactionRepository(database), permanent: true);

  Get.put(PriceController(api), permanent: true);
  Get.put(WatchlistController(prefs), permanent: true);
  Get.put(
    TransactionController(Get.find<TransactionRepository>()),
    permanent: true,
  );
  Get.put(NewsController(api), permanent: true);
  Get.put(PrivacyController(prefs), permanent: true);

  runApp(const EmasKuApp());
}
