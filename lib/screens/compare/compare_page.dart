import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:emaskuid/controllers/price_controller.dart';
import 'package:emaskuid/app/theme/app_theme.dart';
import 'package:emaskuid/core/utils/formatters.dart';
import 'package:emaskuid/data/models/models.dart';
import 'package:emaskuid/screens/compare/compare_entry.dart';
import 'package:emaskuid/widgets/widgets.dart';
import 'package:emaskuid/screens/market/vendor_detail_page.dart';

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  static const String _material = 'gold';
  double? _weight;

  @override
  Widget build(BuildContext context) {
    final price = Get.find<PriceController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Banding Harga')),
      body: Obx(() {
        final all = price.allPrices;
        final weights = _weights(all, _material);
        final weight =
            _weight ??
            (weights.contains(1)
                ? 1
                : (weights.isEmpty ? null : weights.first));

        return AsyncStateView(
          loading: price.loading.value,
          hasData: all.isNotEmpty,
          error: price.error.value,
          emptyMessage: 'Belum ada harga untuk dibandingkan.',
          onRetry: () => price.load(force: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _filters(weight, weights),
              const SizedBox(height: 16),
              ..._comparison(price, weight),
            ],
          ),
        );
      }),
    );
  }

  List<double> _weights(List<GoldPrice> all, String material) {
    final set = <double>{};
    for (final p in all) {
      if (p.material.toLowerCase() == material && p.sellPrice != null) {
        set.add(p.weight);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  Widget _filters(double? weight, List<double> weights) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Berat', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (weights.isEmpty)
              const Text('—')
            else
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: weights.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final w = weights[i];
                    return ChoiceChip(
                      label: Text(Fmt.gram(w)),
                      selected: weight == w,
                      onSelected: (_) => setState(() => _weight = w),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _comparison(PriceController price, double? weight) {
    if (weight == null) return const [SizedBox.shrink()];

    final entries = <CompareEntry>[];
    for (final source in price.sources) {
      final rows = price
          .pricesFor(source.name)
          .where(
            (p) =>
                p.material.toLowerCase() == _material &&
                p.weight == weight &&
                p.sellPrice != null,
          )
          .toList();
      if (rows.isEmpty) continue;
      rows.sort((a, b) => a.sellPrice!.compareTo(b.sellPrice!));
      entries.add(CompareEntry(source, rows.first));
    }
    if (entries.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: Text('Tidak ada toko dengan berat ini.')),
        ),
      ];
    }

    // A buyback above the selling price is an inverted/implausible quote
    // (e.g. the FX-style kursdolar source) and must not win best-price picks.
    final sane = entries.where((e) => (e.price.spread ?? 0) >= 0).toList();
    final ranked = sane.isEmpty ? entries : sane;

    final bestBuy = ranked.reduce(
      (a, b) => a.price.sellPrice! <= b.price.sellPrice! ? a : b,
    );
    final withBuyback = ranked
        .where((e) => e.price.buybackPrice != null)
        .toList();
    final bestSell = withBuyback.isEmpty
        ? null
        : withBuyback.reduce(
            (a, b) => a.price.buybackPrice! >= b.price.buybackPrice! ? a : b,
          );
    entries.sort((a, b) => a.price.sellPrice!.compareTo(b.price.sellPrice!));

    final scheme = Theme.of(context).colorScheme;
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan ${Fmt.gram(weight)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _highlight(
                      icon: Icons.shopping_cart_checkout_rounded,
                      title: 'Beli termurah',
                      vendor: bestBuy.source.displayName,
                      value: Fmt.rupiah(bestBuy.price.sellPrice),
                      color: AppTheme.gain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _highlight(
                      icon: Icons.sell_rounded,
                      title: 'Jual tertinggi',
                      vendor: bestSell?.source.displayName ?? '—',
                      value: Fmt.rupiah(bestSell?.price.buybackPrice),
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        '${entries.length} toko',
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      ...entries.map((e) => _entryTile(e, bestBuy, bestSell)),
    ];
  }

  Widget _highlight({
    required IconData icon,
    required String title,
    required String vendor,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            vendor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          PriceText(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _entryTile(
    CompareEntry entry,
    CompareEntry bestBuy,
    CompareEntry? bestSell,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isBestBuy = entry == bestBuy;
    final isBestSell = bestSell != null && entry == bestSell;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () =>
              Get.to(() => VendorDetailPage(source: entry.source.name)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    VendorAvatar(
                      name: entry.source.displayName,
                      imageUrl: entry.source.favicon,
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.source.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            Fmt.shortMaterialType(entry.price.materialType),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isBestBuy)
                      const Pill(
                        text: 'Termurah',
                        color: AppTheme.gain,
                        icon: Icons.arrow_downward_rounded,
                      )
                    else if (isBestSell)
                      Pill(
                        text: 'Jual terbaik',
                        color: scheme.primary,
                        icon: Icons.arrow_upward_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 6),
                    Expanded(
                      child: StatTile(
                        label: 'Harga beli',
                        value: Fmt.rupiah(entry.price.sellPrice),
                        icon: Icons.shopping_bag_outlined,
                        valueColor: isBestBuy ? AppTheme.gain : null,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: 'Buyback',
                        value: Fmt.rupiah(entry.price.buybackPrice),
                        icon: Icons.sell_outlined,
                        valueColor: isBestSell ? scheme.primary : null,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: 'Selisih',
                        value: Fmt.rupiahCompact(entry.price.spread),
                        icon: Icons.swap_horiz_rounded,
                        dense: true,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
