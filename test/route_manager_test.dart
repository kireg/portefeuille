import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/features/00_app/services/route_manager.dart';
import 'test_harness.dart';

// Ensure Hive and boxes/adapters are initialized for tests
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await initTestHive();
  });

  tearDownAll(() async {
    await tearDownTestHive(tempDir);
  });

  testWidgets('Route addInstitution provides Material ancestor and contains TextFormField',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      onGenerateRoute: RouteManager.onGenerateRoute,
      initialRoute: RouteManager.addInstitution,
    ));

    await tester.pumpAndSettle();

    // Vérifie la présence d'au moins un TextFormField
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
