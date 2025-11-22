// lib/core/data/services/ai_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:portefeuille/core/data/models/transaction_extraction_result.dart';

class AiService {
  final String apiKey;
  late final GenerativeModel _model;

  AiService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash', // Utilisation du modèle le plus rapide/efficace
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1, // Très faible pour la précision factuelle
      ),
    );
  }

  Future<List<TransactionExtractionResult>> extractTransactionData(Uint8List imageBytes) async {
    // Prompt renforcé pour la cohérence des types et dates
    const prompt = '''
    Tu es un expert en extraction de données financières. Analyse ce document (relevé de compte ou d'investissement).
    
    RÈGLES STRICTES :
    1. Extrais les transactions sous forme de tableau JSON.
    2. Dates : Format ISO 8601 strict "YYYY-MM-DD".
    3. Types : Utilise UNIQUEMENT ces valeurs anglaises : "BUY", "SELL", "DIVIDEND", "DEPOSIT", "WITHDRAWAL", "FEES", "INTEREST".
    4. Actifs :
       - Cherche le code ISIN (12 chars) en priorité, à défaut, le Ticker.
       - Type d'actif : "STOCK" (Action), "ETF", "CRYPTO", "BOND", "OTHER".
    5. Nombres : Utilise des points pour les décimales, pas de séparateur de milliers.
    
    FORMAT DE SORTIE :
    [
      {
        "date": "2024-05-20",
        "type": "BUY",
        "amount": 1205.50,
        "quantity": 5.0,
        "price": 240.10,
        "fees": 5.00,
        "ticker": "FR0000120271", 
        "assetName": "TOTALENERGIES",
        "currency": "EUR",
        "assetType": "STOCK"
      }
    ]
    ''';

    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/png', imageBytes),
        ])
      ];

      debugPrint("🤖 [AiService] Analyse Gemini en cours...");
      final response = await _model.generateContent(content);
      final text = response.text;

      if (text == null || text.isEmpty) return [];

      // Nettoyage robuste du JSON (retrait des balises markdown éventuelles)
      String jsonString = text.replaceAll('```json', '').replaceAll('```', '').trim();

      // Gestion du cas où l'IA renvoie un objet seul au lieu d'une liste
      if (jsonString.startsWith('{')) {
        jsonString = '[$jsonString]';
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => TransactionExtractionResult.fromJson(json)).toList();

    } catch (e) {
      debugPrint('❌ [AiService] Erreur : $e');
      return [];
    }
  }
}