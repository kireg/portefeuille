import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/09_imports/services/import_diff_service.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

/// Résultat de la validation pré-sauvegarde.
class ValidationResult {
  final bool isValid;
  final List<ValidationIssue> issues;

  ValidationResult({
    required this.isValid,
    required this.issues,
  });

  /// Retourne uniquement les erreurs critiques.
  List<ValidationIssue> get errors =>
      issues.where((i) => i.severity == ValidationSeverity.error).toList();

  /// Retourne uniquement les avertissements.
  List<ValidationIssue> get warnings =>
      issues.where((i) => i.severity == ValidationSeverity.warning).toList();
}

/// Sévérité d'un problème de validation.
enum ValidationSeverity { error, warning }

/// Un problème identifié lors de la validation.
class ValidationIssue {
  final ValidationSeverity severity;
  final String code;
  final String message;
  final ParsedTransaction? transaction;

  ValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.transaction,
  });
}

/// Service de validation des candidats à l'import.
/// 
/// Vérifie la cohérence des données avant sauvegarde :
/// - Signes des montants selon le type de transaction
/// - Cohérence quantité × prix vs montant
/// - ISIN valides
/// - Dates cohérentes
class ImportValidator {
  /// Valide une liste de candidats avant import.
  ValidationResult validate(List<ImportCandidate> candidates) {
    final issues = <ValidationIssue>[];

    for (final candidate in candidates) {
      if (!candidate.selected) continue;
      final tx = candidate.parsed;

      // Validation du signe du montant
      _validateAmountSign(tx, issues);

      // Validation cohérence quantité × prix
      _validateQuantityPriceConsistency(tx, issues);

      // Validation ISIN
      _validateIsin(tx, issues);

      // Validation date
      _validateDate(tx, issues);
    }

    // Une erreur critique invalide le résultat
    final hasErrors = issues.any((i) => i.severity == ValidationSeverity.error);
    return ValidationResult(isValid: !hasErrors, issues: issues);
  }

  void _validateAmountSign(ParsedTransaction tx, List<ValidationIssue> issues) {
    final amount = tx.amount;

    switch (tx.type) {
      case TransactionType.Buy:
      case TransactionType.Withdrawal:
      case TransactionType.Fees:
        // Ces types devraient avoir un montant négatif (ou zéro)
        if (amount > 0) {
          issues.add(ValidationIssue(
            severity: ValidationSeverity.warning,
            code: 'SIGN_POSITIVE_FOR_OUTFLOW',
            message:
                '${tx.type.name}: montant positif (${amount.toStringAsFixed(2)}€) '
                'attendu négatif pour ${tx.assetName}',
            transaction: tx,
          ));
        }
        break;

      case TransactionType.Sell:
      case TransactionType.Deposit:
      case TransactionType.Dividend:
      case TransactionType.Interest:
        // Ces types devraient avoir un montant positif (ou zéro)
        if (amount < 0) {
          issues.add(ValidationIssue(
            severity: ValidationSeverity.warning,
            code: 'SIGN_NEGATIVE_FOR_INFLOW',
            message:
                '${tx.type.name}: montant négatif (${amount.toStringAsFixed(2)}€) '
                'attendu positif pour ${tx.assetName}',
            transaction: tx,
          ));
        }
        break;

      default:
        // Autres types: pas de vérification de signe stricte
        break;
    }
  }

  void _validateQuantityPriceConsistency(
    ParsedTransaction tx,
    List<ValidationIssue> issues,
  ) {
    // Seulement pour les transactions avec quantité et prix significatifs
    if (tx.quantity <= 0 || tx.price <= 0) return;

    // Tolérance de 5% pour les frais et arrondis
    final expected = tx.quantity * tx.price;
    final actual = tx.amount.abs();
    final tolerance = expected * 0.05;

    if ((actual - expected).abs() > tolerance && expected > 10) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        code: 'QTY_PRICE_MISMATCH',
        message:
            '${tx.assetName}: montant ${actual.toStringAsFixed(2)}€ ≠ '
            '${tx.quantity} × ${tx.price.toStringAsFixed(2)}€ = ${expected.toStringAsFixed(2)}€',
        transaction: tx,
      ));
    }
  }

  void _validateIsin(ParsedTransaction tx, List<ValidationIssue> issues) {
    final isin = tx.isin;
    if (isin == null || isin.isEmpty) return;

    // Format ISIN: 2 lettres + 9 caractères alphanumériques + 1 chiffre de contrôle
    final isinRegex = RegExp(r'^[A-Z]{2}[A-Z0-9]{9}[0-9]$');
    if (!isinRegex.hasMatch(isin)) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        code: 'INVALID_ISIN',
        message: '${tx.assetName}: ISIN "$isin" format invalide',
        transaction: tx,
      ));
    }
  }

  void _validateDate(ParsedTransaction tx, List<ValidationIssue> issues) {
    final now = DateTime.now();
    final tooOld = DateTime(2000, 1, 1);

    if (tx.date.isAfter(now.add(const Duration(days: 1)))) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.error,
        code: 'FUTURE_DATE',
        message: '${tx.assetName}: date dans le futur (${tx.date.toIso8601String().substring(0, 10)})',
        transaction: tx,
      ));
    }

    if (tx.date.isBefore(tooOld)) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        code: 'OLD_DATE',
        message: '${tx.assetName}: date très ancienne (${tx.date.toIso8601String().substring(0, 10)})',
        transaction: tx,
      ));
    }
  }
}
