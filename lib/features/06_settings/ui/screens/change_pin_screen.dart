import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/features/00_app/services/security_service.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _obscureCurrentPin = true;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _changePin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final securityService = context.read<SecurityService>();
    
    // Vérifier le PIN actuel
    final isCurrentPinValid = await securityService.verifyPinCode(_currentPinController.text);
    
    if (!isCurrentPinValid) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le code PIN actuel est incorrect'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Vérifier que le nouveau PIN est différent
    if (_currentPinController.text == _newPinController.text) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le nouveau PIN doit être différent de l\'actuel'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Définir le nouveau PIN
    await securityService.setPinCode(_newPinController.text);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code PIN modifié avec succès'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le code PIN'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Code PIN actuel', style: AppTypography.h3),
                  const SizedBox(height: AppDimens.paddingM),
                  TextFormField(
                    controller: _currentPinController,
                    obscureText: _obscureCurrentPin,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'PIN actuel',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentPin ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscureCurrentPin = !_obscureCurrentPin),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre PIN actuel';
                      }
                      if (value.length < 4) {
                        return 'Le PIN doit contenir au moins 4 chiffres';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nouveau code PIN', style: AppTypography.h3),
                  const SizedBox(height: AppDimens.paddingM),
                  TextFormField(
                    controller: _newPinController,
                    obscureText: _obscureNewPin,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Nouveau PIN',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPin ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscureNewPin = !_obscureNewPin),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nouveau PIN';
                      }
                      if (value.length < 4) {
                        return 'Le PIN doit contenir au moins 4 chiffres';
                      }
                      if (value.length > 6) {
                        return 'Le PIN ne peut pas dépasser 6 chiffres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  TextFormField(
                    controller: _confirmPinController,
                    obscureText: _obscureConfirmPin,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le nouveau PIN',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPin ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer votre nouveau PIN';
                      }
                      if (value != _newPinController.text) {
                        return 'Les codes PIN ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.paddingXL),
            FilledButton.icon(
              onPressed: _isLoading ? null : _changePin,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isLoading ? 'Modification en cours...' : 'Modifier le code PIN'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
