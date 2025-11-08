// lib/features/04_correction/ui/widgets/asset_editor_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';

// Le widget _AssetEditorTile a été extrait ici et rendu public
class AssetEditorTile extends StatefulWidget {
  final Asset asset;
  final VoidCallback onChanged;

  const AssetEditorTile(
      {required Key key, required this.asset, required this.onChanged})
      : super(key: key);

  @override
  State<AssetEditorTile> createState() => _AssetEditorTileState();
}

class _AssetEditorTileState extends State<AssetEditorTile> {
  late final TextEditingController _quantityController;
  late final TextEditingController _pruController;
  late final TextEditingController _priceController;
  late final TextEditingController _yieldController;
  late final FocusNode _quantityFocus;
  late final FocusNode _pruFocus;
  late final FocusNode _priceFocus;
  late final FocusNode _yieldFocus;

  @override
  void initState() {
    super.initState();
    _quantityController =
        TextEditingController(text: widget.asset.quantity.toString());
    _pruController = TextEditingController(
        text: widget.asset.averagePrice.toStringAsFixed(2));
    _priceController = TextEditingController(
        text: widget.asset.currentPrice.toStringAsFixed(2));
    _yieldController = TextEditingController(
        text: (widget.asset.estimatedAnnualYield * 100).toStringAsFixed(2));
    _quantityFocus = FocusNode();
    _pruFocus = FocusNode();
    _priceFocus = FocusNode();
    _yieldFocus = FocusNode();

    _quantityFocus.addListener(() {
      if (!_quantityFocus.hasFocus && mounted)
        _formatControllerOnBlur(_quantityController);
    });
    _pruFocus.addListener(() {
      if (!_pruFocus.hasFocus && mounted)
        _formatControllerOnBlur(_pruController);
    });
    _priceFocus.addListener(() {
      if (!_priceFocus.hasFocus && mounted)
        _formatControllerOnBlur(_priceController);
    });
    _yieldFocus.addListener(() {
      if (!_yieldFocus.hasFocus && mounted)
        _formatControllerOnBlur(_yieldController);
    });
  }

  double? _parse(String input) {
    if (input.isEmpty) return null;
    final cleaned = input.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  String? _numericValidator(String? value, {bool allowNegative = false}) {
    if (value == null || value.trim().isEmpty) return 'Obligatoire';
    final v = _parse(value);
    if (v == null) return 'Nombre invalide';
    if (!allowNegative && v < 0) return 'Valeur négative';
    return null;
  }

  void _formatControllerOnBlur(TextEditingController controller) {
    final val = _parse(controller.text);
    if (val == null) return;
    final locale = Localizations.localeOf(context).toString();
    final nf = NumberFormat.decimalPattern(locale);
    controller.text = nf.format(val);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _pruController.dispose();
    _priceController.dispose();
    _yieldController.dispose();
    _quantityFocus.dispose();
    _pruFocus.dispose();
    _priceFocus.dispose();
    _yieldFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.scaffoldBackgroundColor,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.asset.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.onSurface)),
                ),
                Text(
                  CurrencyFormatter.format(widget.asset.totalValue),
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildEditableField(
                    label: 'Quantité',
                    controller: _quantityController,
                    focusNode: _quantityFocus,
                    onChanged: (value) {
                      widget.asset.quantity =
                          double.tryParse(value.replaceAll(',', '.')) ??
                              widget.asset.quantity;
                      widget.onChanged();
                    },
                    allowNegative: false),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _yieldController,
                    focusNode: _yieldFocus,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Rendement annuel estimé (%)',
                      suffixText: '%',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,\-\.]'))
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => _numericValidator(v, allowNegative: true),
                    onChanged: (value) {
                      final percentage = _parse(value);
                      if (percentage != null)
                        widget.asset.estimatedAnnualYield = percentage / 100.0;
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildEditableField(
                    label: 'PRU',
                    controller: _pruController,
                    suffix: '€',
                    onChanged: (value) {
                      widget.asset.averagePrice =
                          double.tryParse(value.replaceAll(',', '.')) ??
                              widget.asset.averagePrice;
                      widget.onChanged();
                    }),
                const SizedBox(width: 8),
                _buildEditableField(
                    label: 'Prix Actuel',
                    controller: _priceController,
                    suffix: '€',
                    textAlign: TextAlign.right,
                    onChanged: (value) {
                      widget.asset.currentPrice =
                          double.tryParse(value.replaceAll(',', '.')) ??
                              widget.asset.currentPrice;
                      widget.onChanged();
                    }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? suffix,
    TextAlign? textAlign,
    FocusNode? focusNode,
    bool allowNegative = false,
  }) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(allowNegative ? r'[0-9,\-\.]' : r'[0-9,\.]')),
        ],
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) => _numericValidator(v, allowNegative: allowNegative),
        onChanged: onChanged,
      ),
    );
  }
}