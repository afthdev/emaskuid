import 'package:flutter/material.dart';

import 'package:emaskuid/core/testing/test_ids.dart';
import 'package:emaskuid/screens/compare/compare_page.dart';
import 'package:emaskuid/screens/dashboard/dashboard_page.dart';
import 'package:emaskuid/screens/market/market_page.dart';
import 'package:emaskuid/screens/news/news_page.dart';
import 'package:emaskuid/screens/savings/savings_page.dart';
import 'package:emaskuid/widgets/sem_id.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = [
    DashboardPage(),
    MarketPage(),
    ComparePage(),
    SavingsPage(),
    NewsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: SemId(
              TestIds.tabDashboard,
              container: false,
              child: Icon(Icons.home_outlined),
            ),
            selectedIcon: SemId(
              TestIds.tabDashboard,
              container: false,
              child: Icon(Icons.home_rounded),
            ),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: SemId(
              TestIds.tabMarket,
              container: false,
              child: Icon(Icons.storefront_outlined),
            ),
            selectedIcon: SemId(
              TestIds.tabMarket,
              container: false,
              child: Icon(Icons.storefront_rounded),
            ),
            label: 'Pasar',
          ),
          NavigationDestination(
            icon: SemId(
              TestIds.tabCompare,
              container: false,
              child: Icon(Icons.compare_arrows_outlined),
            ),
            selectedIcon: SemId(
              TestIds.tabCompare,
              container: false,
              child: Icon(Icons.compare_arrows_rounded),
            ),
            label: 'Banding',
          ),
          NavigationDestination(
            icon: SemId(
              TestIds.tabSavings,
              container: false,
              child: Icon(Icons.savings_outlined),
            ),
            selectedIcon: SemId(
              TestIds.tabSavings,
              container: false,
              child: Icon(Icons.savings_rounded),
            ),
            label: 'Tabungan',
          ),
          NavigationDestination(
            icon: SemId(
              TestIds.tabNews,
              container: false,
              child: Icon(Icons.article_outlined),
            ),
            selectedIcon: SemId(
              TestIds.tabNews,
              container: false,
              child: Icon(Icons.article_rounded),
            ),
            label: 'Berita',
          ),
        ],
      ),
    );
  }
}
