import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/features/04_journal/ui/widgets/empty_transactions_widget.dart';

void main() {
  testWidgets('EmptyTransactionsWidget displays correct text and button', (WidgetTester tester) async {
    // Arrange
    bool addPressed = false;
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyTransactionsWidget(
            onAdd: () => addPressed = true,
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('Aucune transaction'), findsOneWidget);
    expect(find.textContaining('assurez-vous d\'avoir créé un compte'), findsOneWidget);
    expect(find.textContaining('importer plusieurs transactions'), findsOneWidget);
    
    final buttonFinder = find.text('AJOUTER UNE TRANSACTION MANUELLE'); // AppButton uppercases label
    expect(buttonFinder, findsOneWidget);

    // Test interaction
    await tester.tap(buttonFinder);
    expect(addPressed, isTrue);
  });

  testWidgets('EmptyTransactionsWidget hides button when onAdd is null', (WidgetTester tester) async {
    // Act
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyTransactionsWidget(
            onAdd: null,
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('Aucune transaction'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing); // Assuming AppButton uses a button widget internally or we check for text
    expect(find.text('AJOUTER UNE TRANSACTION MANUELLE'), findsNothing);
  });
}
