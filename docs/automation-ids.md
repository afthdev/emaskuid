# Automation ids (Appium)

Every interactive or assertable element carries a stable accessibility id, set in
code by `SemId` / `SemTag` (`lib/widgets/sem_id.dart`) from the constants in
`lib/core/testing/test_ids.dart`.

`SemId` sets **both**:

| Layer | Value | Used by |
|---|---|---|
| accessibility identifier | same string | Appium `UiAutomator2` (Android `content-desc`), `XCUITest` (iOS accessibility id) |
| widget `ValueKey` | same string | Appium Flutter driver (`byValueKey`), `flutter_test` `find.byKey` |

Nothing renders differently. No dependency added. No layout change.

## Building for QA

Semantics stay off until something asks for them. External drivers cannot always
ask (UiAutomator/XCUITest do not start an accessibility service), so turn the tree
on with a build flag:

```bash
# Android
flutter build apk --debug --dart-define=E2E=true
flutter run --dart-define=E2E=true

# iOS
flutter build ios --debug --dart-define=E2E=true

# Web
flutter build web --dart-define=E2E=true
```

`--dart-define=E2E=true` only calls `SemanticsBinding.instance.ensureSemantics()`
in `lib/main.dart`. Omit it for normal builds — behaviour is untouched.

## Locators

```js
// UiAutomator2 / XCUITest — accessibility id (no `~` guessing needed, it is the id)
await driver.$('~savings.action.add').click();
await driver.$('~tx_form.field.price').setValue('1000000');
// Android native, equivalent:
// new UiSelector().description("savings.action.add")

// Appium Flutter driver — widget key
await driver.execute('flutter:clickElement', { strategy: 'byValueKey', key: 'savings.action.add' });
```

Both strings are identical by design; pick whichever locator your driver version
supports and it will match.

## Naming contract

`<screen>.<region>.<element>`, lowercase, dot separated.

- **Rows are keyed by domain id, never by list index** — `market.vendor.item.alpha`,
  `savings.tx.item.42`, `news.item.https_x_1` (URL slugged).
- Weight chips normalise `1.0` → `1`: `vendor.filter.weight.1`.
- Ids are a public contract. Renaming one breaks QA scripts — treat it like an API
  change and note it in the PR.

## Coverage

### Shell — `lib/screens/shell/main_shell.dart`
| id | element |
|---|---|
| `shell.tab.dashboard` | bottom nav: Beranda |
| `shell.tab.market` | bottom nav: Pasar |
| `shell.tab.compare` | bottom nav: Banding |
| `shell.tab.savings` | bottom nav: Tabungan |
| `shell.tab.news` | bottom nav: Berita |

Tab ids land on the merge node, so the **whole tab** is tappable, not just the icon.

### Shared states — `lib/widgets/async_state_view.dart`, `message_state.dart`
| id | element |
|---|---|
| `common.state.loading` | skeleton loading |
| `common.state.error` | error state |
| `common.state.empty` | empty state |
| `common.action.retry` | retry button inside those states |

Every screen routes through `AsyncStateView`, so these work everywhere. Use them
for waits instead of matching Indonesian copy.

### Dashboard — `dashboard_page.dart`
`dashboard.header.portfolio_card`, `.header.balance`, `.header.grams`,
`.header.buyback`, `.header.profit_loss`, `dashboard.watchlist.card.<source>`,
`dashboard.watchlist.empty`, `dashboard.tx.item.<id>`, `dashboard.tx.empty`,
`dashboard.action.privacy_toggle`, `.action.about`, `.action.view_all_tx`,
`.action.add_transaction`, `.action.compare`, `dashboard.dialog.about`,
`dashboard.dialog.about_close`

### Savings — `savings_page.dart`
`savings.summary.card`, `.summary.grams`, `.summary.avg_price`,
`.summary.net_invested`, `.summary.current_value`, `.summary.profit_loss`,
`.summary.change_percent`, `savings.action.add`, `savings.action.privacy_toggle`,
`savings.tx.empty`, `savings.tx.item.<id>`

### Transaction form — `transaction_form_page.dart`
`tx_form.type.buy`, `tx_form.type.sell`, `tx_form.field.vendor`, `.field.weight`,
`.field.date`, `.field.price`, `.field.note`, `tx_form.summary.total`,
`tx_form.hint.market_price`, `.hint.market_price_loading`,
`tx_form.action.use_market_price`, `tx_form.action.submit`, `tx_form.action.delete`

`.field.price` and `.field.note` put the key on the field itself so
type-into-element works directly. `.field.vendor` / `.field.weight` are dropdowns —
tap then pick the item text.

### Market — `market_page.dart`
`market.field.search`, `market.vendor.item.<source>`,
`market.vendor.watch_toggle.<source>`

### Vendor detail — `vendor_detail_page.dart`
`vendor.header.card`, `vendor.action.set_primary`, `vendor.action.watch`,
`vendor.filter.material.gold|silver`, `vendor.filter.weight.<grams>`,
`vendor.filter.type.all|<type>`, `vendor.chart.card`, `vendor.chart.loading`,
`vendor.chart.empty`, `vendor.price.row.<grams>.<type>`

### Compare — `compare_page.dart`
`compare.filter.weight.<grams>`, `compare.summary.card`,
`compare.summary.best_buy`, `compare.summary.best_sell`,
`compare.summary.vendor_count`, `compare.state.no_vendor`,
`compare.vendor.item.<source>`

### News — `news_page.dart` / `news_detail_page.dart`
`news.item.<url-slug>`, `news.item.<url-slug>.summary_button`,
`news_detail.title`, `news_detail.content`, `news_detail.state.loading`,
`news_detail.state.error`, `news_detail.action.retry`

## Known constraints

1. **Lazy lists.** `ListView` builds only what is on screen. Off-screen elements
   have no semantics node — scroll first, then locate. Do not assume an id exists
   before scrolling.
2. **`IndexedStack` tabs.** Only the active tab is exposed to semantics, so ids
   from other tabs never leak in. Good for QA; safe to assert absence.
3. **`1.0` vs `1`.** Weight ids are normalised by `TestIds._num`. Do not hand-write
   weight ids in scripts; derive them the same way.
4. **Loading/error ids are transient.** Wait on `common.state.loading` to disappear
   before asserting content; do not assert it exists at a fixed moment.
5. **Merged semantics.** Elements inside `MergeSemantics` (bottom nav, segmented
   buttons) absorb the id, so the id sits on the larger merged node — that is
   intended: bigger tap target, TalkBack still reads the label.

## Adding a new id

1. Add a constant (or `static String fn(...)` helper for dynamic values) in
   `lib/core/testing/test_ids.dart`.
2. Wrap the widget: `SemId(TestIds.foo, child: ...)`, or `SemTag(TestIds.foo, child: ...)`
   when the child already needs its own `key` (text fields, rebuild keys).
3. For a target that should be the whole merged group (tabs, segments), pass
   `container: false` so the id merges into the ancestor node.
4. Never reuse a string, never use list indices, never put an id on a wrapper whose
   subtree type changes between states.

## Smoke check without the full suite

```bash
flutter analyze
flutter run --dart-define=E2E=true
# then: DevTools → Widget Inspector → Semantics, or
#       adb shell uiautomator dump  → look for content-desc="..."
```
