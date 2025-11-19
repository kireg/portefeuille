// test/core/utils/isin_validator_test.dart
// Tests unitaires pour IsinValidator

import 'package:flutter_test/flutter_test.dart';
import 'package:portefeuille/core/utils/isin_validator.dart';

void main() {
  group('IsinValidator - Format basique', () {
    test('ISIN valide US0378331005 (Apple) retourne true', () {
      expect(IsinValidator.isValidIsinFormat('US0378331005'), true);
    });

    test('ISIN valide FR0000120073 (Air Liquide) retourne true', () {
      expect(IsinValidator.isValidIsinFormat('FR0000120073'), true);
    });

    test('ISIN valide DE0005140008 (Deutsche Bank) retourne true', () {
      expect(IsinValidator.isValidIsinFormat('DE0005140008'), true);
    });

    test('ISIN trop court retourne false', () {
      expect(IsinValidator.isValidIsinFormat('US037833'), false);
    });

    test('ISIN trop long retourne false', () {
      expect(IsinValidator.isValidIsinFormat('US03783310051234'), false);
    });

    test('Ticker AAPL (4 caractères) retourne false', () {
      expect(IsinValidator.isValidIsinFormat('AAPL'), false);
    });

    test('ISIN commençant par chiffres retourne false', () {
      expect(IsinValidator.isValidIsinFormat('12378331005A'), false);
    });

    test('ISIN avec code pays minuscule retourne true (normalisation)', () {
      // Correction : la validation normalise en majuscules, donc le test doit attendre true
      expect(IsinValidator.isValidIsinFormat('us0378331005'), true);
    });

    test('ISIN avec caractères spéciaux retourne false', () {
      expect(IsinValidator.isValidIsinFormat('US-037833100'), false);
    });

    test('Chaîne vide retourne false', () {
      expect(IsinValidator.isValidIsinFormat(''), false);
    });
  });

  group('IsinValidator - Checksum Luhn', () {
    test('US0378331005 (Apple) avec checksum valide retourne true', () {
      expect(IsinValidator.isValidIsinWithChecksum('US0378331005'), true);
    });

    test('FR0000120073 (Air Liquide) avec checksum valide retourne true', () {
      expect(IsinValidator.isValidIsinWithChecksum('FR0000120073'), true);
    });

    test('ISIN avec checksum invalide retourne false', () {
      // US0378331005 avec dernier chiffre modifié
      expect(IsinValidator.isValidIsinWithChecksum('US0378331006'), false);
    });

    test('ISIN avec format invalide retourne false (checksum)', () {
      expect(IsinValidator.isValidIsinWithChecksum('AAPL'), false);
    });
  });

  group('IsinValidator - Détection automatique', () {
    test('US0378331005 ressemble à un ISIN', () {
      expect(IsinValidator.looksLikeIsin('US0378331005'), true);
    });

    test('FR0000120073 ressemble à un ISIN', () {
      expect(IsinValidator.looksLikeIsin('FR0000120073'), true);
    });

    test('US03783310 (10 caractères) ressemble à un ISIN', () {
      expect(IsinValidator.looksLikeIsin('US03783310'), true);
    });

    test('AAPL (4 caractères) ne ressemble pas à un ISIN', () {
      expect(IsinValidator.looksLikeIsin('AAPL'), false);
    });

    test('Ticker court MSFT ne ressemble pas à un ISIN', () {
      expect(IsinValidator.looksLikeIsin('MSFT'), false);
    });

    test('ISIN avec espaces ressemble à un ISIN (après nettoyage)', () {
      expect(IsinValidator.looksLikeIsin('US 0378331005'), true);
    });

    test('Chaîne commençant par chiffres ne ressemble pas à un ISIN', () {
      expect(IsinValidator.looksLikeIsin('1234567890AB'), false);
    });

    test('Chaîne avec caractères spéciaux ne ressemble pas à un ISIN', () {
      expect(IsinValidator.looksLikeIsin('US-037833-100'), false);
    });
  });

  group('IsinValidator - Nettoyage', () {
    test('Nettoie espaces et met en majuscules', () {
      expect(IsinValidator.cleanIsin('  us0378331005  '), 'US0378331005');
    });

    test('Supprime espaces internes', () {
      expect(IsinValidator.cleanIsin('US 0378 3310 05'), 'US0378331005');
    });

    test('Met en majuscules', () {
      expect(IsinValidator.cleanIsin('fr0000120073'), 'FR0000120073');
    });

    test('ISIN déjà propre reste identique', () {
      expect(IsinValidator.cleanIsin('US0378331005'), 'US0378331005');
    });

    test('Chaîne vide reste vide', () {
      expect(IsinValidator.cleanIsin(''), '');
    });
  });

  group('IsinValidator - Codes pays', () {
    test('Code pays US est valide', () {
      expect(IsinValidator.hasValidCountryCode('US0378331005'), true);
    });

    test('Code pays FR est valide', () {
      expect(IsinValidator.hasValidCountryCode('FR0000120073'), true);
    });

    test('Code pays DE est valide', () {
      expect(IsinValidator.hasValidCountryCode('DE0005140008'), true);
    });

    test('Code pays GB est valide', () {
      expect(IsinValidator.hasValidCountryCode('GB0002374006'), true);
    });

    test('Code pays inconnu XX retourne false', () {
      expect(IsinValidator.hasValidCountryCode('XX0000000000'), false);
    });

    test('ISIN trop court retourne false', () {
      expect(IsinValidator.hasValidCountryCode('US'), false);
    });
  });

  group('IsinValidator - Cas réels', () {
    test('Apple Inc. (US0378331005) est valide', () {
      expect(IsinValidator.isValidIsinFormat('US0378331005'), true);
      expect(IsinValidator.isValidIsinWithChecksum('US0378331005'), true);
    });

    test('Air Liquide (FR0000120073) est valide', () {
      expect(IsinValidator.isValidIsinFormat('FR0000120073'), true);
      expect(IsinValidator.isValidIsinWithChecksum('FR0000120073'), true);
    });

    test('LVMH (FR0000121014) est valide', () {
      expect(IsinValidator.isValidIsinFormat('FR0000121014'), true);
      expect(IsinValidator.isValidIsinWithChecksum('FR0000121014'), true);
    });

    test('Recherche "AAPL" ne déclenche pas validation ISIN', () {
      final cleaned = IsinValidator.cleanIsin('AAPL');
      expect(IsinValidator.looksLikeIsin(cleaned), false);
    });

    test('Recherche "US0378331005" déclenche validation ISIN', () {
      final cleaned = IsinValidator.cleanIsin('US0378331005');
      expect(IsinValidator.looksLikeIsin(cleaned), true);
      expect(IsinValidator.isValidIsinFormat(cleaned), true);
    });

    test(
        'Saisie utilisateur avec espaces "US 0378331005" est valide après nettoyage',
        () {
      final cleaned = IsinValidator.cleanIsin('US 0378331005');
      expect(cleaned, 'US0378331005');
      expect(IsinValidator.isValidIsinFormat(cleaned), true);
    });
  });
}
