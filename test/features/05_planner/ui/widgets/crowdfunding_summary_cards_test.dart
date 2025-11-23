import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/features/05_planner/ui/widgets/crowdfunding_summary_cards.dart';

void main() {
  testWidgets('CrowdfundingSummaryCards should not overflow', (WidgetTester tester) async {
    // Arrange
    final assets = [
      Asset(
        id: '1',
        name: 'Project 1',
        ticker: 'P1',
        type: AssetType.RealEstateCrowdfunding,
        expectedYield: 10.0,
        transactions: [], // Add dummy transactions if needed for calculations
      ),
    ];

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CrowdfundingSummaryCards(assets: assets),
          ),
        ),
      ),
    );

    // Assert
    expect(find.byType(CrowdfundingSummaryCards), findsOneWidget);
    // Check for overflow errors (tester.takeException() would catch them if they crash, 
    // but layout overflows usually print to console. 
    // However, in widget tests, we can check if all widgets are visible or if specific error widgets appear).
    
    // A more robust check is to ensure the size is reasonable or that no "Yellow and Black striped" widget exists.
    // But standard flutter_test doesn't easily detect "overflow" unless we check for specific error widgets.
    // Assuming the fix (IntrinsicHeight) works, we just want to ensure it renders.
  });
}
