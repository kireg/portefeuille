import 'package:flutter/foundation.dart';
import 'package:portefeuille/core/data/models/transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/features/09_imports/services/models/import_mode.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

class ImportCandidate {
  ImportCandidate(
    this.parsed, {
    this.existingMatch,
    this.isModified = false,
    this.selected = true,
  });

  ParsedTransaction parsed;
  final Transaction? existingMatch;
  bool isModified;
  bool selected;

  ImportCandidate copyWith({
    ParsedTransaction? parsed,
    Transaction? existingMatch,
    bool? isModified,
    bool? selected,
  }) {
    return ImportCandidate(
      parsed ?? this.parsed,
      existingMatch: existingMatch ?? this.existingMatch,
      isModified: isModified ?? this.isModified,
      selected: selected ?? this.selected,
    );
  }
}

class ImportDiffResult {
  ImportDiffResult({
    required this.candidates,
    required this.duplicates,
    required this.invalidIsins,
  });

  final List<ImportCandidate> candidates;
  final List<ParsedTransaction> duplicates;
  final List<ParsedTransaction> invalidIsins;
}

class ImportDiffService {
  static const double qtyThreshold = 0.0001;
  static const double amountThreshold = 0.01;
  static final RegExp _isinRegex = RegExp(r'^[A-Z]{2}[A-Z0-9]{9}[0-9]$');

  ImportDiffResult compute({
    required List<ParsedTransaction> parsed,
    required List<Transaction> existing,
    required ImportMode mode,
  }) {
    final List<ParsedTransaction> duplicates = [];
    final List<ParsedTransaction> invalidIsins = [];
    final List<ImportCandidate> candidates = [];

    final existingIdentity = existing.map(_identityKeyExisting).toSet();
    final existingByMatchKey = <String, Transaction>{
      for (final tx in existing) _matchKeyExisting(tx): tx,
    };

    for (final p in parsed) {
      // ISIN validity
      if (p.isin != null && p.isin!.isNotEmpty) {
        if (!_isinRegex.hasMatch(p.isin!)) {
          invalidIsins.add(p);
        }
      }

      // Duplicates by full identity
      final identityKey = _identityKeyParsed(p);
      if (existingIdentity.contains(identityKey)) {
        duplicates.add(p);
        debugPrint('🔎 ImportDiff: duplicate ignored (identity=$identityKey)');
        continue;
      }

      Transaction? existingMatch;
      bool isModified = false;

      if (mode == ImportMode.update) {
        final matchKey = _matchKeyParsed(p);
        existingMatch = existingByMatchKey[matchKey];
        if (existingMatch != null) {
          final qtyDiff = (p.quantity - (existingMatch.quantity ?? 0)).abs();
          final amtDiff = (p.amount - existingMatch.amount).abs();
          if (qtyDiff > qtyThreshold || amtDiff > amountThreshold) {
            isModified = true;
            debugPrint('✏️ ImportDiff: will update existing (match=$matchKey)');
          } else {
            duplicates.add(p);
            debugPrint('🔎 ImportDiff: duplicate (no significant diff)');
            continue;
          }
        }
      }

      candidates.add(ImportCandidate(
        p,
        existingMatch: existingMatch,
        isModified: isModified,
      ));
    }

    return ImportDiffResult(
      candidates: candidates,
      duplicates: duplicates,
      invalidIsins: invalidIsins,
    );
  }

  String _identityKeyParsed(ParsedTransaction tx) {
    final dateKey =
        DateTime(tx.date.year, tx.date.month, tx.date.day).toIso8601String();
    final assetRef = (tx.ticker ?? tx.isin ?? tx.assetName).toLowerCase();
    return '$dateKey|$assetRef|${tx.type}|${tx.quantity.toStringAsFixed(4)}|${tx.amount.toStringAsFixed(2)}';
  }

  String _identityKeyExisting(Transaction tx) {
    final dateKey =
        DateTime(tx.date.year, tx.date.month, tx.date.day).toIso8601String();
    final assetRef = (tx.assetTicker ?? tx.assetName ?? '').toLowerCase();
    final qty = (tx.quantity ?? 0).toStringAsFixed(4);
    return '$dateKey|$assetRef|${tx.type}|$qty|${tx.amount.toStringAsFixed(2)}';
  }

  String _matchKeyParsed(ParsedTransaction tx) {
    final dateKey =
        DateTime(tx.date.year, tx.date.month, tx.date.day).toIso8601String();
    final assetRef = (tx.ticker ?? tx.isin ?? tx.assetName).toLowerCase();
    return '$dateKey|$assetRef|${tx.type}';
  }

  String _matchKeyExisting(Transaction tx) {
    final dateKey =
        DateTime(tx.date.year, tx.date.month, tx.date.day).toIso8601String();
    final assetRef = (tx.assetTicker ?? tx.assetName ?? '').toLowerCase();
    return '$dateKey|$assetRef|${tx.type}';
  }
}
