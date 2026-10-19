import 'package:emaskuid/widgets/price_text.dart';
import 'package:flutter/material.dart';

/// One labelled metric.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    this.dense = false,
    this.sensitive = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;
  final bool dense;
  final bool sensitive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: dense ? 13 : 15, color: scheme.onSurfaceVariant),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: dense ? 11 : 12.5,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        PriceText(
          value,
          sensitive: sensitive,
          style: TextStyle(
            fontSize: dense ? 14 : 17,
            fontWeight: FontWeight.w800,
          ),
          color: valueColor ?? scheme.onSurface,
        ),
      ],
    );
  }
}
