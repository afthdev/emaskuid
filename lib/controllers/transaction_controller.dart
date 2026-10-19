import 'package:get/get.dart';

import 'package:emaskuid/core/utils/portfolio.dart';
import 'package:emaskuid/data/models/models.dart';
import 'package:emaskuid/data/repositories/transaction_repository.dart';

/// Local savings transactions + portfolio math.
class TransactionController extends GetxController {
  TransactionController(this._repo);

  final TransactionRepository _repo;

  final RxList<Transaction> transactions = <Transaction>[].obs;
  final RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      transactions.assignAll(await _repo.all());
    } finally {
      loading.value = false;
    }
  }

  Future<void> add(Transaction tx) async {
    final saved = await _repo.insert(tx);
    transactions.insert(0, saved);
  }

  Future<void> edit(Transaction tx) async {
    await _repo.update(tx);
    final i = transactions.indexWhere((e) => e.id == tx.id);
    if (i >= 0) transactions[i] = tx;
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    transactions.removeWhere((e) => e.id == id);
  }

  List<Transaction> get sorted {
    final list = transactions.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Portfolio get portfolio => Portfolio(transactions);

  double get gramsHeld => portfolio.gramsHeld;

  double get totalBuyCost => portfolio.totalBuyCost;

  double get avgBuyPrice => portfolio.avgBuyPrice;

  double get netInvested => portfolio.netInvested;

  double portfolioValue(double pricePerGram) =>
      portfolio.portfolioValue(pricePerGram);

  double unrealized(double pricePerGram) => portfolio.unrealized(pricePerGram);

  double unrealizedPercent(double pricePerGram) =>
      portfolio.unrealizedPercent(pricePerGram);
}
