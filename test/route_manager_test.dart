import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/features/00_app/services/route_manager.dart';
import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
import 'package:portefeuille/features/00_app/services/institution_service.dart';
import 'package:portefeuille/core/data/models/institution_metadata.dart';
import 'test_harness.dart';

class MockInstitutionService extends InstitutionService {
  @override
  List<InstitutionMetadata> search(String query) => [];
  
  @override
  Future<void> loadInstitutions() async {}
}

class MockPortfolioProvider extends ChangeNotifier implements PortfolioProvider {
  final InstitutionService _institutionService = MockInstitutionService();

  @override
  InstitutionService get institutionService => _institutionService;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
    await tester.pumpWidget(
      ChangeNotifierProvider<PortfolioProvider>(
        create: (_) => MockPortfolioProvider(),
        child: const MaterialApp(
          onGenerateRoute: RouteManager.onGenerateRoute,
          initialRoute: RouteManager.addInstitution,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Vérifie la présence d'au moins un TextFormField
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
