import 'package:flutter/widgets.dart';

/// Tags a widget with a stable automation id.
///
/// Sets two things at once:
/// * the accessibility identifier — surfaces as `content-desc` on Android and
///   the accessibility id on iOS, which is what Appium's UiAutomator2/XCUITest
///   drivers match on;
/// * the widget key — what the Flutter driver (`byValueKey`) and
///   `find.byKey` in widget tests match on.
///
/// Renders nothing: no pixels, no layout change.
class SemId extends StatelessWidget {
  const SemId(this.id, {super.key, required this.child, this.container = true});

  final String id;
  final Widget child;

  /// Whether this widget gets its own semantics node.
  ///
  /// Keep `true` by default. Pass `false` when an ancestor merges semantics
  /// (e.g. the bottom navigation bar) and you want the id to land on that
  /// larger ancestor node instead of a tiny child node.
  final bool container;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: id,
      container: container,
      child: KeyedSubtree(key: ValueKey(id), child: child),
    );
  }
}

/// Same id, no widget key — for widgets that already carry their own key.
class SemTag extends StatelessWidget {
  const SemTag(
    this.id, {
    super.key,
    required this.child,
    this.container = true,
  });

  final String id;
  final Widget child;
  final bool container;

  @override
  Widget build(BuildContext context) {
    return Semantics(identifier: id, container: container, child: child);
  }
}
