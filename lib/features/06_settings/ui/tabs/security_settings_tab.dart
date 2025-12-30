import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_card.dart';
import 'package:portefeuille/features/00_app/services/security_service.dart';
import 'package:portefeuille/features/06_settings/ui/screens/change_pin_screen.dart';

class SecuritySettingsTab extends StatefulWidget {
  const SecuritySettingsTab({super.key});

  @override
  State<SecuritySettingsTab> createState() => _SecuritySettingsTabState();
}

class _SecuritySettingsTabState extends State<SecuritySettingsTab> {
  bool _isSecurityEnabled = false;
  bool _canCheckBiometrics = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecurityState();
  }

  Future<void> _loadSecurityState() async {
    final service = context.read<SecurityService>();
    final enabled = service.isSecurityEnabled;
    final canCheck = await service.canCheckBiometrics;

    if (mounted) {
      setState(() {
        _isSecurityEnabled = enabled;
        _canCheckBiometrics = canCheck;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSecurity(bool value) async {
    final service = context.read<SecurityService>();
    
    if (value) {
      // Activer la sécurité : demander une auth pour confirmer
      // Ou demander de définir un PIN si pas encore fait (simplification ici : on active juste)
      // Idéalement : Flow de création de PIN
      
      // Pour l'instant, on active simplement
      await service.setSecurityEnabled(true);
    } else {
      // Désactiver : demander auth avant de désactiver
      final authenticated = await service.authenticate();
      if (!authenticated) return; // Échec auth, on ne désactive pas
      
      await service.setSecurityEnabled(false);
    }

    if (mounted) {
      setState(() {
        _isSecurityEnabled = service.isSecurityEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verrouillage de l\'application', style: AppTypography.h3),
              const SizedBox(height: AppDimens.paddingM),
              SwitchListTile(
                title: const Text('Activer la sécurité'),
                subtitle: const Text('Demander une authentification au démarrage'),
                value: _isSecurityEnabled,
                onChanged: _toggleSecurity,
                activeThumbColor: AppColors.primary,
              ),
              if (_isSecurityEnabled && _canCheckBiometrics) ...[
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.fingerprint, color: AppColors.primary),
                  title: Text('Biométrie disponible'),
                  subtitle: Text('Face ID / Touch ID sera utilisé si configuré'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        if (_isSecurityEnabled)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code PIN', style: AppTypography.h3),
                const SizedBox(height: AppDimens.paddingM),
                ListTile(
                  title: const Text('Modifier le code PIN'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ChangePinScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
