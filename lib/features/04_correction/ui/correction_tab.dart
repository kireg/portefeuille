import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/account_type.dart';
import 'package:portefeuille/core/utils/currency_formatter.dart';
import 'package:provider/provider.dart';

import '../../00_app/providers/portfolio_provider.dart';


class CorrectionTab extends StatefulWidget {
  const CorrectionTab({super.key});

  @override
  State<CorrectionTab> createState() => _CorrectionTabState();
}

class _CorrectionTabState extends State<CorrectionTab> with AutomaticKeepAliveClientMixin {
  Portfolio? _editedPortfolio;
  bool _hasChanges = false;
  Key _listKey = UniqueKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_editedPortfolio == null) {
      _resetLocalCopy();
    }
  }

  void _resetLocalCopy() {
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    if (portfolioProvider.portfolio != null) {
      _editedPortfolio = portfolioProvider.portfolio!.deepCopy();
    } else {
      _editedPortfolio = null;
    }
    setState(() {
      _listKey = UniqueKey();
      _hasChanges = false;
    });
  }

  void _onDataChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _saveChanges() {
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    if (_editedPortfolio != null) {
      portfolioProvider.updatePortfolio(_editedPortfolio!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modifications enregistrées !'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _hasChanges = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_editedPortfolio == null) {
      return const Center(child: Text("Aucun portefeuille à corriger."));
    }

    final institutions = _editedPortfolio!.institutions;
    const bottomBarHeight = 72.0;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: _hasChanges ? bottomBarHeight : 0),
          child: ListView.builder(
            key: _listKey,
            padding: const EdgeInsets.all(8.0),
            itemCount: institutions.length,
            itemBuilder: (context, instIndex) {
              final inst = institutions[instIndex];
              final instTotal = inst.totalValue;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                color: theme.colorScheme.surface,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  title: Row(
                    children: [
                      Expanded(child: Text(inst.name, style: theme.textTheme.titleLarge)),
                      Text(
                        CurrencyFormatter.format(instTotal),
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  children: inst.accounts.map((account) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Card(
                        color: Color.lerp(theme.colorScheme.surface, theme.colorScheme.background, 0.5),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                  Row(
                                children: [
                                  Text(
                                    account.name,
                                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                                  ),
                                  const SizedBox(width: 8),
                                  // Visible rectangular label showing account type; hovering displays a rectangular info bubble
                                  AccountTypeLabel(
                                    label: account.type.displayName,
                                    description: account.type.description,
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                                    textColor: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                              Text(
                                CurrencyFormatter.format(account.totalValue),
                                style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Liquidités (optionnel)
                                  if (account.type != AccountType.crypto) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: TextFormField(
                                        initialValue: account.cashBalance.toStringAsFixed(2),
                                        decoration: InputDecoration(
                                          labelText: 'Liquidités',
                                          labelStyle: TextStyle(color: theme.colorScheme.primary),
                                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                                          border: const OutlineInputBorder(),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.18)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
                                          ),
                                          isDense: false,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                                          prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
                                          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                          suffixText: '€',
                                        ),
                                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                        textAlignVertical: TextAlignVertical.center,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        onChanged: (value) {
                                          account.cashBalance = double.tryParse(value) ?? account.cashBalance;
                                          _onDataChanged();
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Assets grid - adapts to window width
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Calculate number of columns based on available width
                                      // Target minimum width of 380 for comfortable display
                                      final targetWidth = 380.0;
                                      final spacing = 12.0;
                                      int columns = (constraints.maxWidth / (targetWidth + spacing)).floor();
                                      columns = columns.clamp(1, 3); // Max 3 columns
                                      
                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          childAspectRatio: 1.8, // Adjust based on content height
                                          crossAxisSpacing: spacing,
                                          mainAxisSpacing: spacing,
                                          mainAxisExtent: 180, // Fixed height for each asset tile
                                        ),
                                        itemCount: account.assets.length,
                                        itemBuilder: (context, assetIndex) {
                                          final asset = account.assets[assetIndex];
                                          return _AssetEditorTile(
                                            key: ValueKey('${inst.name}_${account.name}_${asset.ticker}_$assetIndex'),
                                            asset: asset,
                                            onChanged: _onDataChanged,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),

        // Floating sticky action bar when there are changes
        if (_hasChanges)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              bottom: true,
              child: Material(
                elevation: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.12),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modifications non sauvegardées',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pensez à sauvegarder vos changements',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Annuler'),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Annuler les modifications ?'),
                              content: const Text('Toutes les modifications non sauvegardées seront perdues.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Non')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Oui')),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            _resetLocalCopy();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Enregistrer'),
                        onPressed: _saveChanges,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// --- Widget interne pour gérer l'édition d'un seul actif ---

class _AssetEditorTile extends StatefulWidget {
  final Asset asset;
  final VoidCallback onChanged;

  const _AssetEditorTile({required Key key, required this.asset, required this.onChanged}) : super(key: key);

  @override
  State<_AssetEditorTile> createState() => _AssetEditorTileState();
}

class _AssetEditorTileState extends State<_AssetEditorTile> {
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
    _quantityController = TextEditingController(text: widget.asset.quantity.toString());
    _pruController = TextEditingController(text: widget.asset.averagePrice.toStringAsFixed(2));
    _priceController = TextEditingController(text: widget.asset.currentPrice.toStringAsFixed(2));
    _yieldController = TextEditingController(text: (widget.asset.estimatedAnnualYield * 100).toStringAsFixed(2));
    _quantityFocus = FocusNode();
    _pruFocus = FocusNode();
    _priceFocus = FocusNode();
    _yieldFocus = FocusNode();

    _quantityFocus.addListener(() {
      if (!_quantityFocus.hasFocus && mounted) _formatControllerOnBlur(_quantityController);
    });
    _pruFocus.addListener(() {
      if (!_pruFocus.hasFocus && mounted) _formatControllerOnBlur(_pruController);
    });
    _priceFocus.addListener(() {
      if (!_priceFocus.hasFocus && mounted) _formatControllerOnBlur(_priceController);
    });
    _yieldFocus.addListener(() {
      if (!_yieldFocus.hasFocus && mounted) _formatControllerOnBlur(_yieldController);
    });
  }

  // Note: automatic recompute removed — annual yield is entered by the user.

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
      color: theme.scaffoldBackgroundColor, // darker than institution surface to visually separate bubbles
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
            // Top row: name and total value (replace redundant yield display)
            Row(
              children: [
                Expanded(
                  child: Text(widget.asset.name, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)),
                ),
                Text(
                  CurrencyFormatter.format(widget.asset.totalValue),
                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // First row: Quantité (left) and Rendement Ann. Est. (%) (right)
            Row(
              children: [
                _buildEditableField(label: 'Quantité', controller: _quantityController, focusNode: _quantityFocus, onChanged: (value) {
                  widget.asset.quantity = double.tryParse(value.replaceAll(',', '.')) ?? widget.asset.quantity;
                  widget.onChanged();
                }, allowNegative: false),
                const SizedBox(width: 8),
                // Yield field (simple, non-annualized)
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,\-\.]'))],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => _numericValidator(v, allowNegative: true),
                    onChanged: (value) {
                      final percentage = _parse(value);
                      if (percentage != null) widget.asset.estimatedAnnualYield = percentage / 100.0;
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Second row: PRU (left) and Prix Actuel (right)
            Row(
              children: [
                _buildEditableField(label: 'PRU', controller: _pruController, suffix: '€', onChanged: (value) {
                  widget.asset.averagePrice = double.tryParse(value.replaceAll(',', '.')) ?? widget.asset.averagePrice;
                  widget.onChanged();
                }),
                const SizedBox(width: 8),
                _buildEditableField(label: 'Prix Actuel', controller: _priceController, suffix: '€', textAlign: TextAlign.right, onChanged: (value) {
                  widget.asset.currentPrice = double.tryParse(value.replaceAll(',', '.')) ?? widget.asset.currentPrice;
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
          FilteringTextInputFormatter.allow(RegExp(allowNegative ? r'[0-9,\-\.]' : r'[0-9,\.]')),
        ],
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) => _numericValidator(v, allowNegative: allowNegative),
        onChanged: onChanged,
      ),
    );
  }
}

// Small widget: a visible rectangular label for account type that shows a rectangular info-bubble on hover.
class AccountTypeLabel extends StatefulWidget {
  final String label;
  final String description;
  final Color? backgroundColor;
  final Color? textColor;

  const AccountTypeLabel({
    super.key,
    required this.label,
    required this.description,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<AccountTypeLabel> createState() => _AccountTypeLabelState();
}

class _AccountTypeLabelState extends State<AccountTypeLabel> {
  OverlayEntry? _overlayEntry;
  final _hoverKey = GlobalKey();
  Timer? _showTimer;
  Timer? _hideTimer;

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final renderObj = _hoverKey.currentContext?.findRenderObject();
    final overlay = Overlay.of(context);
    if (renderObj == null) return;

    final renderBox = renderObj as RenderBox;
    final target = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        // Rectangular, non-rounded bubble placed above the label when possible
        final left = target.dx;
        final top = target.dy - 8 - 72.0; // try above the label
        return Positioned(
          left: left,
          top: top < 8 ? target.dy + size.height + 8 : top,
          child: Material(
            color: Colors.transparent,
            child: MouseRegion(
              onEnter: (_) {
                // keep it open when pointer moves into overlay
                _hideTimer?.cancel();
              },
              onExit: (_) {
                // hide shortly after leaving overlay
                _hideTimer?.cancel();
                _hideTimer = Timer(const Duration(milliseconds: 200), _hideOverlay);
              },
              child: Container(
                width: 260,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.24)),
                  // rectangular (no rounded corners)
                  borderRadius: BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(widget.description, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

  overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _hideTimer?.cancel();
        _showTimer?.cancel();
        // small delay to avoid flicker
        _showTimer = Timer(const Duration(milliseconds: 120), () {
          _showOverlay();
        });
      },
      onExit: (_) {
        _showTimer?.cancel();
        _hideTimer?.cancel();
        // delay hiding so transient pointer moves don't close it
        _hideTimer = Timer(const Duration(milliseconds: 200), () {
          _hideOverlay();
        });
      },
      child: Container(
        key: _hoverKey,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.12)),
          // rectangular (sharp corners)
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          widget.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: widget.textColor ?? Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }
}
