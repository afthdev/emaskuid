import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:emaskuid/controllers/price_controller.dart';
import 'package:emaskuid/controllers/watchlist_controller.dart';
import 'package:emaskuid/core/utils/formatters.dart';
import 'package:emaskuid/data/models/models.dart';
import 'package:emaskuid/widgets/widgets.dart';
import 'package:emaskuid/screens/market/vendor_detail_page.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = Get.find<PriceController>();
    final watch = Get.find<WatchlistController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pasar & Toko')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Cari toko…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final all = price.sources;
              final items = _query.isEmpty
                  ? all
                  : all
                        .where(
                          (s) =>
                              s.displayName.toLowerCase().contains(_query) ||
                              s.name.toLowerCase().contains(_query),
                        )
                        .toList();
              return AsyncStateView(
                loading: price.loading.value,
                hasData: all.isNotEmpty,
                error: price.error.value,
                emptyMessage: 'Tidak ada toko yang cocok.',
                onRetry: () => price.load(force: true),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _vendorTile(context, price, watch, items[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _vendorTile(
    BuildContext context,
    PriceController price,
    WatchlistController watch,
    PriceSource source,
  ) {
    final ref = price.referencePrice(source.name, weight: 1);

    // Rebuild this tile on its own so the bookmark icon reacts immediately.
    return Obx(() {
      final isPrimary = watch.primary.value == source.name;
      final watched = watch.isWatched(source.name);
      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Get.to(() => VendorDetailPage(source: source.name)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                VendorAvatar(
                  name: source.displayName,
                  imageUrl: source.favicon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              source.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (isPrimary) ...[
                            const SizedBox(width: 6),
                            const Pill(text: 'Utama', icon: Icons.star_rounded),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ref == null
                            ? 'Harga belum tersedia'
                            : '1 gr ${Fmt.rupiah(ref.sellPrice)} • buyback ${Fmt.rupiahCompact(ref.buybackPrice)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: watched ? 'Lepas pantauan' : 'Pantau harga',
                  onPressed: () => watch.toggleWatch(source.name),
                  icon: Icon(
                    watched
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: watched
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
