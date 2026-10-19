/// Widget ids used by automation (Appium) and integration tests.
///
/// Format: `<screen>.<region>.<element>`, lowercase, dot separated.
/// These strings are a contract with the test suites: renaming one is a
/// breaking change. Add new ids here instead of writing string literals in the
/// widgets.
///
/// Dynamic ids (list rows, chips) come from the static helpers at the bottom.
abstract final class TestIds {
  // ---------------------------------------------------------------- shell
  static const tabDashboard = 'shell.tab.dashboard';
  static const tabMarket = 'shell.tab.market';
  static const tabCompare = 'shell.tab.compare';
  static const tabSavings = 'shell.tab.savings';
  static const tabNews = 'shell.tab.news';

  // ------------------------------------------------ shared async states
  // Every screen renders through AsyncStateView, so these cover all of them.
  static const stateLoading = 'common.state.loading';
  static const stateError = 'common.state.error';
  static const stateEmpty = 'common.state.empty';
  static const actionRetry = 'common.action.retry';

  // ------------------------------------------------------------ dashboard
  static const dashPortfolioCard = 'dashboard.header.portfolio_card';
  static const dashBalance = 'dashboard.header.balance';
  static const dashGrams = 'dashboard.header.grams';
  static const dashBuyback = 'dashboard.header.buyback';
  static const dashProfitLoss = 'dashboard.header.profit_loss';
  static const dashPrivacyToggle = 'dashboard.action.privacy_toggle';
  static const dashAbout = 'dashboard.action.about';
  static const dashViewAllTx = 'dashboard.action.view_all_tx';
  static const dashAddTransaction = 'dashboard.action.add_transaction';
  static const dashCompare = 'dashboard.action.compare';
  static const dashEmptyWatchlist = 'dashboard.watchlist.empty';
  static const dashEmptyTx = 'dashboard.tx.empty';
  static const dashAboutDialog = 'dashboard.dialog.about';
  static const dashAboutClose = 'dashboard.dialog.about_close';

  // -------------------------------------------------------------- savings
  static const savingsSummaryCard = 'savings.summary.card';
  static const savingsGrams = 'savings.summary.grams';
  static const savingsAvgPrice = 'savings.summary.avg_price';
  static const savingsNetInvested = 'savings.summary.net_invested';
  static const savingsCurrentValue = 'savings.summary.current_value';
  static const savingsProfitLoss = 'savings.summary.profit_loss';
  static const savingsChangePercent = 'savings.summary.change_percent';
  static const savingsPrivacyToggle = 'savings.action.privacy_toggle';
  static const savingsAddButton = 'savings.action.add';
  static const savingsEmpty = 'savings.tx.empty';

  // -------------------------------------------------------- transaction form
  static const formBuySegment = 'tx_form.type.buy';
  static const formSellSegment = 'tx_form.type.sell';
  static const formVendor = 'tx_form.field.vendor';
  static const formWeight = 'tx_form.field.weight';
  static const formDate = 'tx_form.field.date';
  static const formPrice = 'tx_form.field.price';
  static const formNote = 'tx_form.field.note';
  static const formTotal = 'tx_form.summary.total';
  static const formMarketPriceHint = 'tx_form.hint.market_price';
  static const formMarketPriceLoading = 'tx_form.hint.market_price_loading';
  static const formUseMarketPrice = 'tx_form.action.use_market_price';
  static const formSubmit = 'tx_form.action.submit';
  static const formDelete = 'tx_form.action.delete';

  // --------------------------------------------------------------- market
  static const marketSearch = 'market.field.search';

  // -------------------------------------------------------- vendor detail
  static const vendorHeader = 'vendor.header.card';
  static const vendorPrimaryButton = 'vendor.action.set_primary';
  static const vendorWatchToggle = 'vendor.action.watch';
  static const vendorChartCard = 'vendor.chart.card';
  static const vendorChartLoading = 'vendor.chart.loading';
  static const vendorChartEmpty = 'vendor.chart.empty';

  // -------------------------------------------------------------- compare
  static const compareSummary = 'compare.summary.card';
  static const compareBestBuy = 'compare.summary.best_buy';
  static const compareBestSell = 'compare.summary.best_sell';
  static const compareVendorCount = 'compare.summary.vendor_count';
  static const compareNoVendor = 'compare.state.no_vendor';

  // ----------------------------------------------------------------- news
  static const newsDetailTitle = 'news_detail.title';
  static const newsDetailContent = 'news_detail.content';
  static const newsDetailLoading = 'news_detail.state.loading';
  static const newsDetailError = 'news_detail.state.error';
  static const newsDetailRetry = 'news_detail.action.retry';

  // ------------------------------------------------- dynamic id helpers
  // Rows keyed by domain id (stable across reorders), never by list index.
  static String dashWatchCard(String source) =>
      'dashboard.watchlist.card.$source';
  static String dashTxItem(Object id) => 'dashboard.tx.item.$id';

  static String savingsTxItem(Object id) => 'savings.tx.item.$id';

  static String marketVendorItem(String source) => 'market.vendor.item.$source';
  static String marketWatchToggle(String source) =>
      'market.vendor.watch_toggle.$source';

  static String vendorMaterialSegment(String material) =>
      'vendor.filter.material.$material';
  static String vendorWeightChip(num weight) =>
      'vendor.filter.weight.${_num(weight)}';
  static String vendorTypeChip(String type) =>
      'vendor.filter.type.${_slug(type)}';
  static String vendorPriceRow(num weight, String type) =>
      'vendor.price.row.${_num(weight)}.${_slug(type)}';

  static String compareWeightChip(num weight) =>
      'compare.filter.weight.${_num(weight)}';
  static String compareVendorItem(String source) =>
      'compare.vendor.item.$source';

  /// News articles are keyed by published URL (stable, no image/ordering deps).
  static String newsItem(String url) => 'news.item.${_slug(url)}';
  static String newsSummaryButton(String url) =>
      'news.item.${_slug(url)}.summary_button';

  /// Keeps ids lowercase and dot-safe for dynamic values (URLs, type names).
  static String _slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  /// `1.0` and `1` must produce the same id, so weights never drift.
  static String _num(num value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';
}
