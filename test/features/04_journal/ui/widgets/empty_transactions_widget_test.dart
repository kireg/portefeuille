import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/features/04_journal/ui/widgets/empty_transactions_widget.dart';

void main() {
  testWidgets('EmptyTransactionsWidget displays correct text and cards', (WidgetTester tester) async {
    // Set a larger screen size to avoid overflow
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;

    // Arrange
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyTransactionsWidget(
            onImportHub: () {},
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('Aucune transaction'), findsOneWidget);
    expect(find.text('Commencez par alimenter votre journal.'), findsOneWidget);
    expect(find.text('Ajouter / Importer'), findsOneWidget);
    
    // Reset size
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('EmptyTransactionsWidget works without callback', (WidgetTester tester) async {
    // Act
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyTransactionsWidget(
            onImportHub: null,
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('Aucune transaction'), findsOneWidget);
  });
}
