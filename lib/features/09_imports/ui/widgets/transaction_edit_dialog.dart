import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/widgets/inputs/app_dropdown.dart';
import 'package:portefeuille/core/ui/widgets/inputs/app_text_field.dart';
import 'package:portefeuille/features/09_imports/services/pdf/statement_parser.dart';

class TransactionEditDialog extends StatefulWidget {
  final ParsedTransaction transaction;
  final Function(ParsedTransaction) onSave;

  const TransactionEditDialog({
    super.key,
    required this.transaction,
    required this.onSave,
  });

  @override
  State<TransactionEditDialog> createState() => _TransactionEditDialogState();
}

class _TransactionEditDialogState extends State<TransactionEditDialog> {
  late TextEditingController _dateController;
  late TextEditingController _assetNameController;
  late TextEditingController _isinController;
  late TextEditingController _quantityController;
  late TextEditingController _amountController;
  late TransactionType _type;
  late AssetType _assetType;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.transaction.date.toIso8601String().split('T')[0]);
    _assetNameController = TextEditingController(text: widget.transaction.assetName);
    _isinController = TextEditingController(text: widget.transaction.isin ?? '');
    _quantityController = TextEditingController(text: widget.transaction.quantity.toString());
    _amountController = TextEditingController(text: widget.transaction.amount.toString());
    _type = widget.transaction.type;
    _assetType = widget.transaction.assetType ?? AssetType.Stock;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _assetNameController.dispose();
    _isinController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final date = DateTime.tryParse(_dateController.text) ?? widget.transaction.date;
    final quantity = double.tryParse(_quantityController.text) ?? widget.transaction.quantity;
    final amount = double.tryParse(_amountController.text) ?? widget.transaction.amount;
    final price = quantity > 0 ? amount / quantity : 0.0;

    final updated = ParsedTransaction(
      date: date,
      type: _type,
      assetName: _assetNameController.text,
      isin: _isinController.text.isEmpty ? null : _isinController.text,
      ticker: widget.transaction.ticker,
      quantity: quantity,
      price: price,
      amount: amount,
      fees: widget.transaction.fees,
      currency: widget.transaction.currency,
      assetType: _assetType,
    );

    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text("Modifier la transaction"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: "Date (YYYY-MM-DD)",
              controller: _dateController,
            ),
            const SizedBox(height: 12),
            AppDropdown<TransactionType>(
              label: "Type",
              value: _type,
              items: TransactionType.values.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.toString().split('.').last),
              )).toList(),
              onChanged: (val) => setState(() => _type = val!),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "Nom de l'actif",
              controller: _assetNameController,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "ISIN",
              controller: _isinController,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: "Quantité",
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: "Montant Total",
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppDropdown<AssetType>(
              label: "Type d'actif",
              value: _assetType,
              items: AssetType.values.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.toString().split('.').last),
              )).toList(),
              onChanged: (val) => setState(() => _assetType = val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text("Enregistrer"),
        ),
      ],
    );
  }
}
