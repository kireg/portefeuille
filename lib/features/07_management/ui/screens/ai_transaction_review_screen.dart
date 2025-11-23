// lib/features/07_management/ui/screens/ai_transaction_review_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/components/app_screen.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';

import 'package:portefeuille/core/data/models/transaction_extraction_result.dart';
import 'package:portefeuille/core/data/models/transaction.dart' as model;
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/00_app/providers/transaction_provider.dart';

import 'package:portefeuille/features/07_management/models/draft_transaction.dart';
import 'package:portefeuille/features/07_management/ui/widgets/draft_transaction_card.dart';

class AiTransactionReviewScreen extends StatefulWidget {
  final String accountId;
  final List<TransactionExtractionResult> extractedResults;

  const AiTransactionReviewScreen({
    super.key,
    required this.accountId,
    required this.extractedResults,
  });

  @override
  State<AiTransactionReviewScreen> createState() => _AiTransactionReviewScreenState();
}

class _AiTransactionReviewScreenState extends State<AiTransactionReviewScreen> {
  late List<DraftTransaction> _drafts;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _drafts = widget.extractedResults
        .map((r) => DraftTransaction.fromExtraction(r))
        .toList();
    // La détection de doublons (loadExistingTransactions) devrait être ici
  }

  void _removeDraft(int index) {
    setState(() {
      _drafts.removeAt(index);
    });
  }

  Future<void> _validateAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      final provider = context.read<TransactionProvider>();
      int successCount = 0;

      final transactions = _drafts.map((draft) => model.Transaction(
        id: const Uuid().v4(),
        accountId: widget.accountId,
        type: draft.type,
        date: draft.date,
        amount: draft.amount,
        assetTicker: draft.ticker.isNotEmpty ? draft.ticker : null,
        assetName: draft.name.isNotEmpty ? draft.name : null,
        quantity: draft.quantity > 0 ? draft.quantity : null,
        price: draft.price > 0 ? draft.price : null,
        fees: draft.fees,
        assetType: draft.assetType,
        priceCurrency: draft.currency,
        notes: "Import IA",
      )).toList();

      await provider.addTransactions(transactions);
      successCount = transactions.length;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$successCount transactions importées !"),
            backgroundColor: AppColors.success,
            showCloseIcon: true,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $e"),
            backgroundColor: AppColors.error,
            showCloseIcon: true,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appCurrency = context.select<SettingsProvider, String>((s) => s.baseCurrency);

    return AppScreen(
      appBar: AppBar(
        title: Text("Vérification (${_drafts.length})", style: AppTypography.h3),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt, color: AppColors.primary),
            onPressed: (_drafts.isEmpty || _isSaving) ? null : _validateAndSave,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _drafts.isEmpty
                ? Center(child: Text("Aucune transaction à importer.", style: AppTypography.body))
                : Form(
              key: _formKey,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                itemCount: _drafts.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                itemBuilder: (ctx, index) {
                  return DraftTransactionCard(
                    draft: _drafts[index],
                    appCurrency: appCurrency,
                    onDelete: () => _removeDraft(index),
                  );
                },
              ),
            ),
          ),
          // Bouton de validation flottant en bas si nécessaire, ou garder dans l'AppBar
          if (_drafts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: AppButton(
                label: "VALIDER L'IMPORT",
                onPressed: _isSaving ? null : _validateAndSave,
                isLoading: _isSaving,
                icon: Icons.check_circle_outline,
              ),
            ),
        ],
      ),
    );
  }
}