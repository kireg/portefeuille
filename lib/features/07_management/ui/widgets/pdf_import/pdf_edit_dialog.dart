import 'package:flutter/material.dart';
import 'package:portefeuille/features/07_management/services/pdf/statement_parser.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';

class PdfEditDialog extends StatefulWidget {
  final ParsedTransaction transaction;
  final ValueChanged<ParsedTransaction> onSave;

  const PdfEditDialog({
    super.key,
    required this.transaction,
    required this.onSave,
  });

  @override
  State<PdfEditDialog> createState() => _PdfEditDialogState();
}

class _PdfEditDialogState extends State<PdfEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _tickerController;
  late TextEditingController _isinController;
  late TextEditingController _qtyController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.transaction.assetName);
    _tickerController = TextEditingController(text: widget.transaction.ticker);
    _isinController = TextEditingController(text: widget.transaction.isin);
    _qtyController = TextEditingController(text: widget.transaction.quantity.toString());
    _priceController = TextEditingController(text: widget.transaction.price.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tickerController.dispose();
    _isinController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: Text('Modifier la transaction', style: AppTypography.h3),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom de l\'actif'),
            ),
            TextField(
              controller: _tickerController,
              decoration: const InputDecoration(labelText: 'Ticker (ex: AAPL)'),
            ),
            TextField(
              controller: _isinController,
              decoration: const InputDecoration(labelText: 'ISIN (ex: FR0000120073)'),
            ),
            TextField(
              controller: _qtyController,
              decoration: const InputDecoration(labelText: 'Quantité'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Prix unitaire'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            final newTx = ParsedTransaction(
              date: widget.transaction.date,
              type: widget.transaction.type,
              assetName: _nameController.text,
              ticker: _tickerController.text.isEmpty ? null : _tickerController.text,
              isin: _isinController.text.isEmpty ? null : _isinController.text,
              quantity: double.tryParse(_qtyController.text) ?? widget.transaction.quantity,
              price: double.tryParse(_priceController.text) ?? widget.transaction.price,
              amount: (double.tryParse(_qtyController.text) ?? widget.transaction.quantity) * 
                      (double.tryParse(_priceController.text) ?? widget.transaction.price),
              fees: widget.transaction.fees,
              currency: widget.transaction.currency,
            );
            widget.onSave(newTx);
            Navigator.pop(context);
          },
          child: Text('Enregistrer', style: AppTypography.label.copyWith(color: AppColors.primary)),
        ),
      ],
    );
  }
}
