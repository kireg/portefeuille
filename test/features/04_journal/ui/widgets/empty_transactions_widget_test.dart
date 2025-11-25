import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/features/04_journal/ui/widgets/empty_transactions_widget.dart';

void main() {
  testWidgets('EmptyTransactionsWidget displays correct text and cards', (WidgetTester tester) async {
    // Arrange
    bool importHubPressed = false;
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyTransactionsWidget(
            onImportHub: () => importHubPressed = true,
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('Aucune transaction'), findsOneWidget);
    expect(find.textContaining('assurez-vous d\'avoir créé un compte'), findsOneWidget);
    expect(find.textContaining('importer plusieurs transactions'), findsOneWidget);
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
