import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:emaskuid/controllers/price_controller.dart';
import 'package:emaskuid/controllers/transaction_controller.dart';
import 'package:emaskuid/core/utils/formatters.dart';
import 'package:emaskuid/data/models/models.dart';
import 'package:emaskuid/widgets/widgets.dart';

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({super.key, this.existing});

  final Transaction? existing;

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  final price = Get.find<PriceController>();
  final wallet = Get.find<TransactionController>();

  TxType _type = TxType.buy;
  String? _source;
  double? _weight;
  DateTime _date = DateTime.now();

  /// Set once the user types a price, so date changes stop overwriting it.
  bool _priceEdited = false;
  bool _loadingPrice = false;
  GoldPrice? _suggested;
  int _requestId = 0;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _type = e.type;
      _source = e.vendorSource;
      _weight = e.weight;
      _priceCtrl.text = Fmt.formatNumberValue(e.weight * e.pricePerGram);
      _noteCtrl.text = e.note ?? '';
      _date = e.date;
      _priceEdited = true;
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// The price entered is the TOTAL for the chosen weight (market lookup
  /// returns the bar price, e.g. the 10 gr price), so it is not multiplied again.
  double get _enteredPrice => Fmt.parseNumberInput(_priceCtrl.text);

  double get _total => _enteredPrice;

  double get _pricePerGram {
    final w = _weight;
    if (w == null || w == 0) return 0;
    return _enteredPrice / w;
  }

  List<double> _weightsFor(String? source) {
    // Read a map member unconditionally so the wrapping Obx always subscribes,
    // even before a toko is chosen.
    final bySource = price.pricesBySource;
    final noData = bySource.isEmpty; // read before the `||` short-circuits
    if (source == null || noData) return const [];
    final set = <double>{};
    for (final p in bySource[source] ?? const <GoldPrice>[]) {
      if (p.material.toLowerCase() == 'gold') set.add(p.weight);
    }
    return set.toList()..sort();
  }

  void _onVendorChanged(String? source) {
    final weights = _weightsFor(source);
    setState(() {
      _source = source;
      _weight = weights.isEmpty
          ? null
          : (weights.contains(1) ? 1 : weights.first);
      _priceEdited = false;
      _suggested = null;
    });
    _refreshSuggestion();
  }

  void _onWeightChanged(double? weight) {
    setState(() => _weight = weight);
    _refreshSuggestion();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    _refreshSuggestion();
  }

  /// Look up the toko's recorded price at or before the chosen date.
  Future<void> _refreshSuggestion() async {
    final source = _source;
    final weight = _weight;
    if (source == null || weight == null) {
      setState(() {
        _suggested = null;
        _loadingPrice = false;
      });
      return;
    }
    final id = ++_requestId;
    setState(() => _loadingPrice = true);

    GoldPrice? found;
    try {
      found = await price.priceOnDate(source, weight: weight, date: _date);
    } catch (_) {
      found = null;
    }
    if (!mounted || id != _requestId) return;
    setState(() {
      _suggested = found;
      _loadingPrice = false;
      if (!_priceEdited && found?.sellPrice != null) {
        _priceCtrl.text = Fmt.formatNumberValue(found!.sellPrice!);
      }
    });
  }

  void _useMarketPrice() {
    final value = _suggested?.sellPrice;
    if (value == null) return;
    setState(() {
      _priceCtrl.text = Fmt.formatNumberValue(value);
      _priceEdited = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_source == null || _weight == null) {
      Get.snackbar('Belum lengkap', 'Pilih toko dan berat terlebih dahulu.');
      return;
    }
    final source = price.sourceByName(_source!);
    final tx = Transaction(
      id: widget.existing?.id,
      type: _type,
      vendorSource: _source!,
      vendorName: source?.displayName ?? _source!,
      materialType: _suggested?.materialType ?? widget.existing?.materialType,
      weight: _weight!,
      pricePerGram: _pricePerGram,
      date: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (_isEdit) {
      await wallet.edit(tx);
    } else {
      await wallet.add(tx);
    }
    if (mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ubah Transaksi' : 'Tambah Transaksi'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            SegmentedButton<TxType>(
              segments: const [
                ButtonSegment(
                  value: TxType.buy,
                  label: Text('Beli'),
                  icon: Icon(Icons.south_west_rounded),
                ),
                ButtonSegment(
                  value: TxType.sell,
                  label: Text('Jual'),
                  icon: Icon(Icons.north_east_rounded),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 18),

            // 1. Toko
            Obx(() {
              final sources = price.sources;
              final current = _source;
              final hasCurrent =
                  current != null && !sources.any((s) => s.name == current);
              return DropdownButtonFormField<String>(
                initialValue: current,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Toko',
                  prefixIcon: Icon(Icons.storefront_rounded),
                ),
                items: [
                  if (hasCurrent)
                    DropdownMenuItem(value: current, child: Text(current)),
                  for (final s in sources)
                    DropdownMenuItem(value: s.name, child: Text(s.displayName)),
                ],
                onChanged: _onVendorChanged,
                validator: (v) => v == null ? 'Wajib diisi' : null,
              );
            }),
            const SizedBox(height: 14),

            // 2. Weight
            Obx(() {
              final weights = _weightsFor(_source);
              final items = <double>{...weights, ?_weight}.toList()..sort();

              // Prices may arrive after the toko was picked; settle a default.
              if (_source != null && _weight == null && weights.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _weight != null) return;
                  setState(
                    () => _weight = weights.contains(1) ? 1 : weights.first,
                  );
                  _refreshSuggestion();
                });
              }

              return DropdownButtonFormField<double>(
                key: ValueKey('weight-${_source ?? ''}'),
                initialValue: _weight,
                decoration: const InputDecoration(
                  labelText: 'Berat',
                  prefixIcon: Icon(Icons.scale_rounded),
                  suffixText: 'gram',
                ),
                items: items
                    .map(
                      (w) =>
                          DropdownMenuItem(value: w, child: Text(Fmt.gram(w))),
                    )
                    .toList(),
                onChanged: items.isEmpty ? null : _onWeightChanged,
                validator: (v) => v == null ? 'Pilih berat' : null,
              );
            }),
            const SizedBox(height: 14),

            // 3. Date
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  prefixIcon: Icon(Icons.event_rounded),
                  suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                ),
                child: Text(Fmt.date(_date)),
              ),
            ),
            const SizedBox(height: 14),

            // 4. Price (custom, or the toko's price on that date)
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [ThousandsInputFormatter()],
              onChanged: (_) => setState(() => _priceEdited = true),
              decoration: const InputDecoration(
                labelText: 'Harga total',
                prefixText: 'Rp',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
              validator: (v) =>
                  _enteredPrice <= 0 ? 'Harga harus lebih dari 0' : null,
            ),
            const SizedBox(height: 10),
            _priceHint(scheme),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.calculate_rounded, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total'),
                        Text(
                          '@ ${Fmt.rupiah(_pricePerGram)}/gr'
                          '${_weight == null ? '' : ' • ${Fmt.gram(_weight)}'}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Fmt.rupiah(_total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. Note
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Transaksi'),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  await wallet.delete(widget.existing!.id!);
                  if (mounted) Get.back();
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Hapus'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: scheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Tells the user what the market price was on the chosen date and lets them
  /// apply it instead of typing a custom price.
  Widget _priceHint(ColorScheme scheme) {
    if (_source == null || _weight == null) {
      return Text(
        'Pilih toko dan berat untuk memakai harga pasar pada tanggal ini.',
        style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
      );
    }
    if (_loadingPrice) {
      return Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Mencari harga pasar pada ${Fmt.date(_date)}…',
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
        ],
      );
    }

    final suggested = _suggested;
    if (suggested?.sellPrice == null) {
      return Text(
        'Harga pasar untuk tanggal ini tidak tersedia. Isi harga secara manual.',
        style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harga pasar ${Fmt.date(Fmt.parseDate(suggested!.recordedDate))}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${Fmt.rupiah(suggested.sellPrice)} untuk ${Fmt.gram(suggested.weight)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: _useMarketPrice, child: const Text('Pakai')),
        ],
      ),
    );
  }
}
