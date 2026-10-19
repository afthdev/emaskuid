import 'package:emaskuid/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Gold gradient hero card used on the dashboard.
class GoldHeroCard extends StatelessWidget {
  const GoldHeroCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B2E06), Color(0xFF7A6516), AppTheme.gold],
        ),
      ),
      child: child,
    );
  }
}
