// lib/features/07_management/ui/widgets/draft_transaction_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/features/07_management/models/draft_transaction.dart';
import 'package:portefeuille/core/data/models/transaction_type.dart';
import 'package:portefeuille/core/data/models/asset_type.dart';

class DraftTransactionCard extends StatefulWidget {
  final DraftTransaction draft;
  final String appCurrency;
  final VoidCallback onDelete;

  const DraftTransactionCard({
    super.key,
    required this.draft,
    required this.appCurrency,
    required this.onDelete,
  });

  @override
  State<DraftTransactionCard> createState() => _DraftTransactionCardState();
}

class _DraftTransactionCardState extends State<DraftTransactionCard> {
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(widget.draft.date));
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  // Helper pour le style des inputs dans la carte (compacts)
  InputDecoration _getInputDecoration(String label, {String? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.caption,
      suffixText: suffix,
      suffixStyle: AppTypography.caption.copyWith(color: AppColors.primary),
      filled: true,
      fillColor: AppColors.background, // Contraste avec la carte (Surface)
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.draft.isDuplicate ? AppColors.warning : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        border: widget.draft.isDuplicate ? Border.all(color: borderColor) : null,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: AppCard(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          children: [
            // BANDEAU DOUBLON
            if (widget.draft.isDuplicate)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Doublon potentiel détecté",
                      style: AppTypography.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            // --- LIGNE 1 : DROPDOWNS (Types) ---
            Row(
              children: [
                // Type Transaction
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<TransactionType>(
                    value: widget.draft.type,
                    decoration: _getInputDecoration('Type'),
                    dropdownColor: AppColors.surfaceLight,
                    style: AppTypography.bodyBold,
                    isExpanded: true,
                    items: TransactionType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        // UTILISATION DE DISPLAYNAME (Français)
                        child: Text(t.displayName, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => widget.draft.type = v!),
                  ),
                ),
                const SizedBox(width: 12),

                // Type Actif
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<AssetType>(
                    value: widget.draft.assetType,
                    decoration: _getInputDecoration('Actif'),
                    dropdownColor: AppColors.surfaceLight,
                    style: AppTypography.body,
                    isExpanded: true,
                    items: AssetType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        // UTILISATION DE DISPLAYNAME (Français)
                        child: Text(t.displayName, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => widget.draft.assetType = v!),
                  ),
                ),

                const SizedBox(width: 8),
                // Bouton Supprimer
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),

            const SizedBox(height: 12),

            // --- LIGNE 2 : Date & Montant ---
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: _getInputDecoration("Date"),
                    style: AppTypography.body,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: widget.draft.date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                                surface: AppColors.surfaceLight,
                                onSurface: AppColors.textPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          widget.draft.date = picked;
                          _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: widget.draft.amount.toStringAsFixed(2),
                    decoration: _getInputDecoration("Total", suffix: widget.appCurrency),
                    style: AppTypography.bodyBold,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onSaved: (v) => widget.draft.amount = double.parse(v!.replaceAll(',', '.')),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Si pas mouvement de fonds, afficher détails actif
            if (widget.draft.type != TransactionType.Deposit &&
                widget.draft.type != TransactionType.Withdrawal) ...[

              // --- LIGNE 3 : Ticker & Nom ---
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: widget.draft.ticker,
                      decoration: _getInputDecoration("Ticker/ISIN"),
                      style: AppTypography.body,
                      textCapitalization: TextCapitalization.characters,
                      onSaved: (v) => widget.draft.ticker = v ?? '',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: widget.draft.name,
                      decoration: _getInputDecoration("Nom de l'actif"),
                      style: AppTypography.body,
                      onSaved: (v) => widget.draft.name = v ?? '',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // --- LIGNE 4 : Détails Prix ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: widget.draft.quantity.toString(),
                      decoration: _getInputDecoration("Qté"),
                      style: AppTypography.body,
                      keyboardType: TextInputType.number,
                      onSaved: (v) => widget.draft.quantity = double.tryParse(v?.replaceAll(',', '.') ?? '0') ?? 0.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: widget.draft.price.toString(),
                      decoration: _getInputDecoration("Prix U."),
                      style: AppTypography.body,
                      keyboardType: TextInputType.number,
                      onSaved: (v) => widget.draft.price = double.tryParse(v?.replaceAll(',', '.') ?? '0') ?? 0.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: widget.draft.fees.toString(),
                      decoration: _getInputDecoration("Frais"),
                      style: AppTypography.body,
                      keyboardType: TextInputType.number,
                      onSaved: (v) => widget.draft.fees = double.tryParse(v?.replaceAll(',', '.') ?? '0') ?? 0.0,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Juste la description pour les dépôts
              TextFormField(
                initialValue: widget.draft.name,
                decoration: _getInputDecoration("Description"),
                style: AppTypography.body,
                onSaved: (v) => widget.draft.name = v ?? '',
              ),
            ]
          ],
        ),
      ),
    );
  }
}