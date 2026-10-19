import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:emaskuid/controllers/price_controller.dart';
import 'package:emaskuid/controllers/watchlist_controller.dart';
import 'package:emaskuid/app/theme/app_theme.dart';
import 'package:emaskuid/core/testing/test_ids.dart';
import 'package:emaskuid/core/utils/formatters.dart';
import 'package:emaskuid/data/models/models.dart';
import 'package:emaskuid/widgets/widgets.dart';

class VendorDetailPage extends StatefulWidget {
  const VendorDetailPage({super.key, required this.source});

  final String source;

  @override
  State<VendorDetailPage> createState() => _VendorDetailPageState();
}

class _VendorDetailPageState extends State<VendorDetailPage> {
  final PriceController price = Get.find();
  final WatchlistController watch = Get.find();

  String _material = 'gold';
  double? _selectedWeight;
  String? _selectedType;
  bool _ready = false;
  bool _loadingHistory = false;
  List<GoldPrice> _history = const [];

  @override
  void dispose() {
    super.dispose();
  }

  List<double> _weights(List<GoldPrice> rows, String material) {
    final set = <double>{};
    for (final p in rows) {
      if (p.material.toLowerCase() == material) set.add(p.weight);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> _types(List<GoldPrice> rows, String material) {
    final set = <String>{};
    for (final p in rows) {
      if (p.material.toLowerCase() == material &&
          p.materialType.trim().isNotEmpty) {
        set.add(p.materialType.trim());
      }
    }
    return set.toList()..sort();
  }

  List<GoldPrice> _rowsFor(List<GoldPrice> rows, String material) {
    final list = rows
        .where((p) => p.material.toLowerCase() == material)
        .toList();
    list.sort((a, b) => a.weight.compareTo(b.weight));
    return list;
  }

  Future<void> _loadHistory() async {
    if (_selectedWeight == null) return;
    setState(() => _loadingHistory = true);
    try {
      final items = await price.history(
        widget.source,
        weight: _selectedWeight,
        material: _material,
      );
      if (!mounted) return;
      setState(() => _history = items);
    } catch (_) {
      if (mounted) setState(() => _history = const []);
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  void _selectMaterial(String material, List<double> weights) {
    setState(() {
      _material = material;
      _selectedType = null;
      _selectedWeight = weights.contains(1)
          ? 1
          : (weights.isEmpty ? null : weights.first);
      _history = const [];
    });
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Toko')),
      body: Obx(() {
        final src = price.sourceByName(widget.source);
        final rows = price.pricesFor(widget.source);
        final weights = _weights(rows, _material);

        // Kick off the default history fetch once prices are available.
        if (!_ready && weights.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _ready) return;
            setState(() {
              _ready = true;
              _selectedWeight = weights.contains(1) ? 1 : weights.first;
            });
            _loadHistory();
          });
        }

        return AsyncStateView(
          loading: price.loading.value,
          hasData: rows.isNotEmpty,
          error: price.error.value,
          emptyMessage: 'Toko ini belum mengirim data harga.',
          onRetry: () => price.load(force: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _header(context, src, rows),
              const SizedBox(height: 16),
              _materialToggle(context, rows),
              const SizedBox(height: 12),
              if (weights.isNotEmpty) _weightSelector(weights),
              const SizedBox(height: 16),
              _typeFilter(rows),
              const SizedBox(height: 16),
              _chartCard(context),
              const SizedBox(height: 20),
              Text(
                'Harga terbaru',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ..._rowsFor(rows, _material)
                  .where(
                    (p) =>
                        _selectedType == null ||
                        p.materialType.trim() == _selectedType,
                  )
                  .map((p) => _priceRow(context, p)),
            ],
          ),
        );
      }),
    );
  }

  /// Filter chips for the gold type (materialType) shown in "Harga terbaru".
  Widget _typeFilter(List<GoldPrice> rows) {
    final types = _types(rows, _material);
    if (types.length < 2) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis emas',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: types.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == 0) {
                return SemId(
                  TestIds.vendorTypeChip('all'),
                  child: ChoiceChip(
                    label: const Text('Semua'),
                    selected: _selectedType == null,
                    onSelected: (_) => setState(() => _selectedType = null),
                  ),
                );
              }
              final type = types[i - 1];
              return SemId(
                TestIds.vendorTypeChip(type),
                child: ChoiceChip(
                  label: Text(Fmt.shortMaterialType(type)),
                  selected: _selectedType == type,
                  onSelected: (_) => setState(() => _selectedType = type),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, PriceSource? src, List<GoldPrice> rows) {
    final isPrimary = watch.primary.value == widget.source;
    final watched = watch.isWatched(widget.source);
    final latestDate = rows.isEmpty
        ? null
        : Fmt.parseDate(rows.first.recordedDate);

    return SemId(
      TestIds.vendorHeader,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  VendorAvatar(
                    name: src?.displayName ?? widget.source,
                    imageUrl: src?.favicon,
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          src?.displayName ?? widget.source,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          latestDate == null
                              ? 'Data terakhir —'
                              : 'Diperbarui ${Fmt.date(latestDate)}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SemId(
                      TestIds.vendorPrimaryButton,
                      child: FilledButton.icon(
                        onPressed: isPrimary
                            ? null
                            : () => watch.setPrimary(widget.source),
                        icon: Icon(
                          isPrimary
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                        ),
                        label: Text(isPrimary ? 'Toko Utama' : 'Jadikan Utama'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SemId(
                    TestIds.vendorWatchToggle,
                    child: IconButton.outlined(
                      tooltip: watched ? 'Lepas pantauan' : 'Pantau',
                      onPressed: () => watch.toggleWatch(widget.source),
                      icon: Icon(
                        watched
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _materialToggle(BuildContext context, List<GoldPrice> rows) {
    final hasSilver = rows.any((p) => p.material.toLowerCase() == 'silver');
    if (!hasSilver) return const SizedBox.shrink();
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: 'gold',
          label: SemId(
            TestIds.vendorMaterialSegment('gold'),
            container: false,
            child: const Text('Emas'),
          ),
          icon: const Icon(Icons.workspace_premium_rounded),
        ),
        ButtonSegment(
          value: 'silver',
          label: SemId(
            TestIds.vendorMaterialSegment('silver'),
            container: false,
            child: const Text('Perak'),
          ),
          icon: const Icon(Icons.diamond_outlined),
        ),
      ],
      selected: {_material},
      onSelectionChanged: (s) {
        final material = s.first;
        final weights = _weights(rows, material);
        _selectMaterial(material, weights);
      },
    );
  }

  Widget _weightSelector(List<double> weights) {
    return Wrap(
      spacing: 8,
      children: weights
          .map(
            (w) => SemId(
              TestIds.vendorWeightChip(w),
              child: ChoiceChip(
                label: Text(Fmt.gram(w)),
                selected: _selectedWeight == w,
                onSelected: (_) {
                  setState(() => _selectedWeight = w);
                  _loadHistory();
                },
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _chartCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SemId(
      TestIds.vendorChartCard,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Riwayat harga ${_selectedWeight == null ? '' : Fmt.gram(_selectedWeight)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              SizedBox(
                height: 210,
                child: _loadingHistory
                    ? const SemId(
                        TestIds.vendorChartLoading,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _buildChart(context, scheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, ColorScheme scheme) {
    final data = _history.where((p) => p.sellPrice != null).toList();
    if (data.length < 2) {
      return SemId(
        TestIds.vendorChartEmpty,
        child: Center(
          child: Text(
            'Riwayat belum cukup untuk grafik.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }
    // API returns newest first; chart wants chronological order.
    final ordered = data.reversed.toList();
    final spots = <FlSpot>[
      for (var i = 0; i < ordered.length; i++)
        FlSpot(i.toDouble(), ordered[i].sellPrice!),
    ];
    final values = ordered.map((e) => e.sellPrice!).toList();
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final pad = math.max((maxV - minV) * 0.15, maxV * 0.005);
    final interval = math.max((maxV - minV + pad * 2) / 4, 1).toDouble();
    final labelEvery = math.max(1, (ordered.length / 4).floor()).toDouble();

    return LineChart(
      LineChartData(
        minY: minV - pad,
        maxY: maxV + pad,
        minX: 0,
        maxX: (ordered.length - 1).toDouble(),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 54,
              interval: interval,
              getTitlesWidget: (value, meta) => Text(
                Fmt.rupiahCompact(value),
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: labelEvery,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= ordered.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    Fmt.dateShort(Fmt.parseDate(ordered[i].recordedDate)),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItems: (touched) => touched.map((spot) {
              final i = spot.x.round();
              final item = (i >= 0 && i < ordered.length) ? ordered[i] : null;
              return LineTooltipItem(
                Fmt.rupiah(spot.y),
                TextStyle(
                  color: scheme.onInverseSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                children: item == null
                    ? null
                    : [
                        TextSpan(
                          text:
                              '\n${Fmt.date(Fmt.parseDate(item.recordedDate))}',
                          style: TextStyle(
                            color: scheme.onInverseSurface.withValues(
                              alpha: 0.8,
                            ),
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppTheme.gold,
            barWidth: 2.6,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.gold.withValues(alpha: 0.35),
                  AppTheme.gold.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(BuildContext context, GoldPrice p) {
    final scheme = Theme.of(context).colorScheme;
    final selected = p.weight == _selectedWeight;
    return SemId(
      TestIds.vendorPriceRow(p.weight, p.materialType),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.4)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    Fmt.gram(p.weight).replaceAll(' gr', ''),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Fmt.shortMaterialType(p.materialType),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Buyback ${Fmt.rupiah(p.buybackPrice)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 116,
                  child: PriceText(
                    Fmt.rupiah(p.sellPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    align: Alignment.centerRight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
