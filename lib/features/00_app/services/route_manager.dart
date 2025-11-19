// lib/features/00_app/services/route_manager.dart
//
// Gestion centralisée des routes nommées de l'application.
// Élimine les imports directs d'écrans entre features.
//
// Migration Phase 2 - Étape 2.1: RouteManager centralisé

import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/features/01_launch/ui/splash_screen.dart';
import 'package:portefeuille/features/01_launch/ui/launch_screen.dart';
import 'package:portefeuille/features/02_dashboard/ui/dashboard_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_institution_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_account_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_transaction_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/edit_transaction_screen.dart';
import 'package:portefeuille/features/07_management/ui/screens/add_savings_plan_screen.dart';

/// Définition de toutes les routes nommées de l'application
class RouteManager {
  // ==================== ROUTES SYSTÈME ====================
  static const String splash = '/splash';
  static const String launch = '/launch';
  static const String dashboard = '/dashboard';

  // ==================== ROUTES 07_MANAGEMENT ====================
  /// Ajouter une nouvelle institution
  static const String addInstitution = '/management/add-institution';

  /// Ajouter un nouveau compte
  static const String addAccount = '/management/add-account';

  /// Ajouter une nouvelle transaction
  static const String addTransaction = '/management/add-transaction';

  /// Éditer une transaction existante
  static const String editTransaction = '/management/edit-transaction';

  /// Ajouter un plan d'épargne
  static const String addSavingsPlan = '/management/add-savings-plan';

  // ==================== ROUTE MAPPER ====================
  /// Map des routes vers leurs constructeurs
  /// À utiliser avec MaterialApp.onGenerateRoute
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(settings, const SplashScreen());
      case launch:
        return _buildRoute(settings, const LaunchScreen());
      case dashboard:
        return _buildRoute(settings, const DashboardScreen());
      case addInstitution:
        return _buildRoute(settings, const AddInstitutionScreen());
      case addAccount:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final institutionId = args['institutionId'] as String?;
        final accountToEdit = args['accountToEdit'] as Account?;

        if (institutionId == null) {
          return _buildErrorRoute(settings, 'institutionId manquant');
        }

        return _buildRoute(
          settings,
          AddAccountScreen(
            institutionId: institutionId,
            accountToEdit: accountToEdit,
          ),
        );
      case addTransaction:
        // AddTransactionScreen n'a pas de paramètres, c'est un écran simple
        return _buildRoute(settings, const AddTransactionScreen());
      case editTransaction:
        // EditTransactionScreen requiert une transaction existante
        final args = settings.arguments as Map<String, dynamic>?;
        final existingTransaction = args?['existingTransaction'] as Transaction?;

        if (existingTransaction == null) {
          return _buildErrorRoute(settings, 'existingTransaction manquant');
        }

        return _buildRoute(
          settings,
          EditTransactionScreen(existingTransaction: existingTransaction),
        );
      case addSavingsPlan:
        return _buildRoute(settings, const AddSavingsPlanScreen());
      default:
        return _buildErrorRoute(settings, 'Route non trouvée: ${settings.name}');
    }
  }

  /// Construit un MaterialPageRoute standard
  static MaterialPageRoute<dynamic> _buildRoute(
    RouteSettings settings,
    Widget page,
  ) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }

  /// Construit une route d'erreur
  static MaterialPageRoute<dynamic> _buildErrorRoute(
    RouteSettings settings,
    String errorMessage,
  ) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Erreur de navigation')),
        body: Center(
          child: Text(errorMessage),
        ),
      ),
      settings: settings,
    );
  }
}

