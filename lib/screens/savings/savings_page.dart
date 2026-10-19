import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:emaskuid/controllers/price_controller.dart';
import 'package:emaskuid/controllers/transaction_controller.dart';
import 'package:emaskuid/controllers/watchlist_controller.dart';
import 'package:emaskuid/app/theme/app_theme.dart';
import 'package:emaskuid/core/utils/formatters.dart';
import 'package:emaskuid/data/models/models.dart';
import 'package:emaskuid/widgets/widgets.dart';
import 'package:emaskuid/screens/savings/transaction_form_page.dart';

class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = Get.find<TransactionController>();
    final price = Get.find<PriceController>();
    final watch = Get.find<WatchlistController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabungan Emas'),
        actions: const [PrivacyToggleButton()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const TransactionFormPage()),
        tooltip: 'Tambah transaksi',
        child: const Icon(Icons.add_rounded),
      ),
      body: Obx(() {
        final primary = watch.primary.value;
        final perGram = primary.isEmpty
            ? 0.0
            : (price.valuationPerGram(primary) ?? 0.0);
        return RefreshIndicator(
          onRefresh: () async {
            await price.load(force: true);
            await wallet.load();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _summaryCard(context, wallet, perGram),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    '${wallet.transactions.length} entri',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (wallet.transactions.isEmpty)
                _empty(context)
              else
                ...wallet.sorted.map((t) => _tile(context, t)),
            ],
          ),
        );
      }),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    TransactionController wallet,
    double perGram,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final hasPrice = perGram > 0;
    final value = hasPrice ? wallet.portfolioValue(perGram) : 0.0;
    final pl = hasPrice ? wallet.unrealized(perGram) : 0.0;
    final plPct = hasPrice ? wallet.unrealizedPercent(perGram) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Emas Tersimpan',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            PriceText(
              Fmt.gram(wallet.gramsHeld),
              sensitive: true,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Harga rata-rata',
                    value: Fmt.rupiah(wallet.avgBuyPrice),
                    icon: Icons.price_check_rounded,
                    dense: true,
                    sensitive: true,
                  ),
                ),
                Expanded(
                  child: StatTile(
                    label: 'Modal tersimpan',
                    value: Fmt.rupiahCompact(wallet.netInvested),
                    icon: Icons.account_balance_wallet_outlined,
                    dense: true,
                    sensitive: true,
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Nilai saat ini',
                    value: hasPrice ? Fmt.rupiahCompact(value) : '—',
                    icon: Icons.trending_up_rounded,
                    dense: true,
                    sensitive: true,
                  ),
                ),
                Expanded(
                  child: StatTile(
                    label: 'Untung/Rugi',
                    value: hasPrice ? Fmt.signedRupiah(pl) : '—',
                    valueColor: hasPrice ? gainLossColor(context, pl) : null,
                    icon: Icons.insights_rounded,
                    dense: true,
                    sensitive: true,
                  ),
                ),
                Expanded(
                  child: StatTile(
                    label: 'Perubahan',
                    value: hasPrice ? Fmt.percent(plPct) : '—',
                    valueColor: hasPrice ? gainLossColor(context, plPct) : null,
                    icon: Icons.percent_rounded,
                    dense: true,
                    sensitive: true,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                hasPrice
                    ? 'Untung/rugi dihitung dari harga buyback toko pada hari ini.'
                    : 'Pilih toko utama di tab Pasar untuk melihat nilai & untung/rugi.',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.savings_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 10),
            const Text(
              'Belum ada transaksi. Tekan "Tambah" untuk mulai mencatat.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, Transaction t) {
    final isBuy = t.type == TxType.buy;
    final tint = isBuy ? AppTheme.gain : AppTheme.loss;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onTap: () => Get.to(() => TransactionFormPage(existing: t)),
          leading: CircleAvatar(
            backgroundColor: tint.withValues(alpha: 0.14),
            child: Icon(
              isBuy ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: tint,
            ),
          ),
          title: Text(
            '${t.type.label} ${Fmt.gram(t.weight)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${t.vendorName}\n${Fmt.date(t.date)}'
            '${t.note != null && t.note!.isNotEmpty ? ' • ${t.note}' : ''}',
            style: const TextStyle(fontSize: 12.5),
          ),
          isThreeLine: true,
          trailing: SizedBox(
            width: 118,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceText(
                  Fmt.rupiah(t.total),
                  sensitive: true,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  align: Alignment.centerRight,
                ),
                PriceText(
                  '@ ${Fmt.rupiah(t.pricePerGram)}/gr',
                  sensitive: true,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  align: Alignment.centerRight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
