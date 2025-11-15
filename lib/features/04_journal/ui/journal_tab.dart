// lib/features/04_journal/ui/journal_tab.dart

import 'package:flutter/material.dart';
import 'package:portefeuille/core/ui/theme/app_theme.dart';
import 'package:portefeuille/features/04_journal/ui/views/synthese_view.dart';
import 'package:portefeuille/features/04_journal/ui/views/transactions_view.dart';

class JournalTab extends StatefulWidget {
  const JournalTab({super.key});

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // En-tête avec titre
        AppTheme.buildScreenTitle(
          context: context,
          title: 'Journal',
          centered: true,
        ),
        // TabBar
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.account_balance_outlined),
              text: 'Synthèse Actifs',
            ),
            Tab(
              icon: Icon(Icons.receipt_long_outlined),
              text: 'Transactions',
            ),
          ],
        ),
        // TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              SyntheseView(),
              TransactionsView(),
            ],
          ),
        ),
      ],
    );
  }
}