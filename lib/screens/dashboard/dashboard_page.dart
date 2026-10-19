import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:emaskuid/controllers/price_controller.dart';
import 'package:emaskuid/controllers/privacy_controller.dart';
import 'package:emaskuid/controllers/transaction_controller.dart';
import 'package:emaskuid/controllers/watchlist_controller.dart';
import 'package:emaskuid/core/config/app_config.dart';
import 'package:emaskuid/core/testing/test_ids.dart';
import 'package:emaskuid/app/theme/app_theme.dart';
import 'package:emaskuid/core/utils/formatters.dart';
import 'package:emaskuid/data/api/api_client.dart';
import 'package:emaskuid/data/models/models.dart';
import 'package:emaskuid/widgets/widgets.dart';
import 'package:emaskuid/screens/compare/compare_page.dart';
import 'package:emaskuid/screens/savings/savings_page.dart';
import 'package:emaskuid/screens/savings/transaction_form_page.dart';
import 'package:emaskuid/screens/market/vendor_detail_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final price = Get.find<PriceController>();
    final wallet = Get.find<TransactionController>();
    final watch = Get.find<WatchlistController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: [
          const PrivacyToggleButton(testId: TestIds.dashPrivacyToggle),
          SemId(
            TestIds.dashAbout,
            child: IconButton(
              tooltip: 'Tentang & status API',
              onPressed: () => _showAbout(context),
              icon: const Icon(Icons.info_outline_rounded),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (price.loading.value && !price.hasData) {
          return const AsyncStateView(
            loading: true,
            hasData: false,
            onRetry: _noop,
            child: SizedBox.shrink(),
          );
        }
        if (price.error.value.isNotEmpty && !price.hasData) {
          return AsyncStateView(
            loading: false,
            hasData: false,
            error: price.error.value,
            onRetry: () => price.load(force: true),
            child: const SizedBox.shrink(),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            await price.load(force: true);
            await wallet.load();
          },
          child: _content(context, price, wallet, watch),
        );
      }),
    );
  }

  Widget _content(
    BuildContext context,
    PriceController price,
    TransactionController wallet,
    WatchlistController watch,
  ) {
    final primary = watch.primary.value;
    final perGram = primary.isEmpty
        ? 0.0
        : (price.valuationPerGram(primary) ?? 0.0);
    final hasTx = wallet.transactions.isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _portfolioCard(
            context,
            price,
            wallet,
            watch,
            primary,
            perGram,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: SemId(
                  TestIds.dashAddTransaction,
                  child: FilledButton.icon(
                    onPressed: () => Get.to(() => const TransactionFormPage()),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Transaksi'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SemId(
                  TestIds.dashCompare,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () => Get.to(() => const ComparePage()),
                    icon: const Icon(Icons.compare_arrows_rounded),
                    label: const Text('Banding'),
                  ),
                ),
              ),
            ],
          ),
        ),
        SectionTitle(
          title: 'Pantauan Toko',
          action: watch.watchlist.isEmpty
              ? null
              : Text(
                  '${watch.watchlist.length} toko',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
        if (watch.watchlist.isEmpty)
          _emptyWatchlistCard(context)
        else
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: watch.watchlist.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SemId(
                TestIds.dashWatchCard(watch.watchlist[i]),
                child: _watchCard(context, price, watch.watchlist[i]),
              ),
            ),
          ),
        SectionTitle(
          title: 'Transaksi Terakhir',
          action: hasTx
              ? SemId(
                  TestIds.dashViewAllTx,
                  child: TextButton(
                    onPressed: () => Get.to(() => const SavingsPage()),
                    child: const Text('Lihat semua'),
                  ),
                )
              : null,
        ),
        if (!hasTx)
          _emptyTxCard(context)
        else
          ...wallet.sorted.take(4).map((t) => _txTile(context, t)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Text(
            price.lastUpdated.value.isEmpty
                ? 'Harga dari logam-mulia-api'
                : 'Harga diperbarui ${price.lastUpdated.value}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _portfolioCard(
    BuildContext context,
    PriceController price,
    TransactionController wallet,
    WatchlistController watch,
    String primary,
    double perGram,
  ) {
    final hasPrice = perGram > 0;
    final hidden = Get.find<PrivacyController>().hidden.value;
    final value = hasPrice ? wallet.portfolioValue(perGram) : 0.0;
    final pl = hasPrice ? wallet.unrealized(perGram) : 0.0;
    final plPct = hasPrice ? wallet.unrealizedPercent(perGram) : 0.0;

    return SemId(
      TestIds.dashPortfolioCard,
      child: GoldHeroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nilai Tabungan Emas',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    primary.isEmpty
                        ? 'Toko belum dipilih'
                        : (price.sourceByName(primary)?.displayName ?? primary),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SemId(
              TestIds.dashBalance,
              child: PriceText(
                hasPrice ? Fmt.rupiah(value) : '—',
                sensitive: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _heroMetric(
                  'Simpanan',
                  Fmt.gram(wallet.gramsHeld),
                  testId: TestIds.dashGrams,
                  sensitive: true,
                ),
                Container(
                  width: 1,
                  height: 34,
                  margin: const EdgeInsets.only(right: 12),
                  color: Colors.white24,
                ),
                _heroMetric(
                  'Buyback/gr',
                  hasPrice ? Fmt.rupiah(perGram) : '—',
                  testId: TestIds.dashBuyback,
                ),
                Container(
                  width: 1,
                  height: 34,
                  margin: const EdgeInsets.only(right: 12),
                  color: Colors.white24,
                ),
                _heroMetric(
                  hasPrice && !hidden ? 'P/L (${Fmt.percent(plPct)})' : 'P/L',
                  hasPrice ? Fmt.signedRupiah(pl) : '—',
                  testId: TestIds.dashProfitLoss,
                  sensitive: true,
                  color: hasPrice
                      ? (pl >= 0
                            ? const Color(0xFFB9F6CA)
                            : const Color(0xFFFFCDD2))
                      : null,
                ),
              ],
            ),
            if (!hasPrice) ...[
              const SizedBox(height: 12),
              Text(
                'Pilih toko utama di tab Pasar untuk menghitung nilai tabungan.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _heroMetric(
    String label,
    String value, {
    required String testId,
    Color? color,
    bool sensitive = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
            ),
            const SizedBox(height: 4),
            SemId(
              testId,
              child: PriceText(
                value,
                sensitive: sensitive,
                style: TextStyle(
                  color: color ?? Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _watchCard(
    BuildContext context,
    PriceController price,
    String source,
  ) {
    final src = price.sourceByName(source);
    final ref = price.referencePrice(source, weight: 1);
    return GestureDetector(
      onTap: () => Get.to(() => VendorDetailPage(source: source)),
      child: Container(
        width: 176,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                VendorAvatar(
                  name: src?.displayName ?? source,
                  imageUrl: src?.favicon,
                  size: 34,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    src?.displayName ?? source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Harga 1 gr',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              Fmt.rupiah(ref?.sellPrice),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            Text(
              'Buyback ${Fmt.rupiahCompact(ref?.buybackPrice)}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyWatchlistCard(BuildContext context) {
    return SemId(
      TestIds.dashEmptyWatchlist,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Belum ada toko dipantau. Tambahkan dari tab Pasar.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyTxCard(BuildContext context) {
    return SemId(
      TestIds.dashEmptyTx,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.savings_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Belum ada transaksi. Catat pembelian emas pertamamu.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _txTile(BuildContext context, Transaction t) {
    final isBuy = t.type == TxType.buy;
    return SemId(
      TestIds.dashTxItem(t.id ?? t.date.millisecondsSinceEpoch),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Card(
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            leading: CircleAvatar(
              backgroundColor: (isBuy ? AppTheme.gain : AppTheme.loss)
                  .withValues(alpha: 0.14),
              child: Icon(
                isBuy ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: isBuy ? AppTheme.gain : AppTheme.loss,
              ),
            ),
            title: Text('${t.type.label} ${Fmt.gram(t.weight)}'),
            subtitle: Text(
              '${t.vendorName} • ${Fmt.date(t.date)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: SizedBox(
              width: 112,
              child: PriceText(
                Fmt.rupiah(t.total),
                sensitive: true,
                align: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    final api = Get.find<ApiClient>();
    bool? healthy;
    try {
      healthy = await api.health();
    } catch (_) {
      healthy = false;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => SemId(
        TestIds.dashAboutDialog,
        child: AlertDialog(
          title: const Text('Tentang ${AppConfig.appName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aplikasi tabungan emas & pembanding harga toko.'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    healthy == true
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    size: 18,
                    color: healthy == true ? AppTheme.gain : AppTheme.loss,
                  ),
                  const SizedBox(width: 6),
                  Text(healthy == true ? 'API online' : 'API tidak terjangkau'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Dokumentasi API:',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SelectableText(
                AppConfig.apiDocsUrl,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            SemId(
              TestIds.dashAboutClose,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _noop() {}
