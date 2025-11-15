// lib/core/data/services/api_service.dart
// REMPLACEZ LE FICHIER COMPLET

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'dart:convert';

/// Cache pour les prix (15 minutes)
class _CacheEntry {
  final double value;
  final DateTime timestamp;
  _CacheEntry(this.value) : timestamp = DateTime.now();

  bool get isStale =>
      DateTime.now().difference(timestamp) > const Duration(minutes: 15);
}

/// Modèle pour les suggestions de recherche
class TickerSuggestion {
  final String ticker;
  final String name;
  final String exchange;
  TickerSuggestion(
      {required this.ticker, required this.name, required this.exchange});
}

// --- NOUVEAU : Objets de résultat pour un meilleur feedback ---
enum ApiSource { Fmp, Yahoo, Cache, None }

class PriceResult {
  final double? price;
  final ApiSource source;
  final String ticker;

  PriceResult(this.price, this.source, this.ticker);
}
// --- FIN NOUVEAU ---

/// Service responsable des appels réseau pour les données financières.
/// Gère la logique de cache et la stratégie FMP > Yahoo.
class ApiService {
  final SettingsProvider _settingsProvider;
  final Map<String, _CacheEntry> _priceCache = {};

  // --- CORRECTION : CHAMP MANQUANT ---
  final http.Client _httpClient;
  // --- FIN CORRECTION ---

  // Cache pour la recherche (24h)
  final Map<String, List<TickerSuggestion>> _searchCache = {};
  final Map<String, DateTime> _searchCacheTimestamps = {};

  // --- CONSTRUCTEUR REFRACTORISÉ (Injection de dépendances) ---
  ApiService({
    required SettingsProvider settingsProvider,
    http.Client? httpClient, // Optionnel, principalement pour les tests
  })  : _settingsProvider = settingsProvider,
        _httpClient = httpClient ?? http.Client(); // Utilise un client réel par défaut

  /// Récupère le prix pour un ticker.
  /// Gère le cache et la stratégie de fallback.
  /// MODIFIÉ : Retourne un PriceResult pour un feedback détaillé.
  Future<PriceResult> getPrice(String ticker) async {
    try {
      // 1. Vérifier le cache
      final cached = _priceCache[ticker];
      if (cached != null && !cached.isStale) {
        return PriceResult(cached.value, ApiSource.Cache, ticker);
      }

      // 2. Si le cache est vide ou obsolète, appeler le réseau
      double? price;
      final bool hasFmpKey = _settingsProvider.hasFmpApiKey;

      if (hasFmpKey) {
        price = await _fetchFromFmp(ticker);
        if (price != null) {
          _priceCache[ticker] = _CacheEntry(price);
          return PriceResult(price, ApiSource.Fmp, ticker);
        }
      }

      // 3. Stratégie 2 : Yahoo (Fallback ou si FMP n'a pas de clé)
      price = await _fetchFromYahoo(ticker);
      // 4. Mettre à jour le cache et retourner
      if (price != null) {
        _priceCache[ticker] = _CacheEntry(price);
        // Si FMP était activé mais a échoué, c'est un fallback Yahoo
        // Si FMP n'était pas activé, c'est une source Yahoo standard
        return PriceResult(price, ApiSource.Yahoo, ticker);
      }

      // 5. Échec complet
      return PriceResult(null, ApiSource.None, ticker);
    } catch (e) {
      // Capturer TOUTES les exceptions non gérées
      debugPrint("⚠️ Erreur inattendue lors de la récupération du prix pour $ticker : $e");
      return PriceResult(null, ApiSource.None, ticker);
    }
  }

  /// Tente de récupérer un prix via FMP (Financial Modeling Prep)
  Future<double?> _fetchFromFmp(String ticker) async {
    if (!_settingsProvider.hasFmpApiKey) return null;
    final apiKey = _settingsProvider.fmpApiKey!;

    // --- CORRECTION ENDPOINT (de la réponse précédente) ---
    final uri = Uri.parse(
        'https://financialmodelingprep.com/api/v3/quote/$ticker?apikey=$apiKey');
    // --- FIN CORRECTION ---

    try {
      final response =
      await _httpClient.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final price = data[0]['price'];
          if (price is num) {
            return price.toDouble();
          }
        }
      }
      debugPrint("Erreur FMP pour $ticker (Status: ${response.statusCode}): ${response.body}");
      return null;
    } catch (e) {
      debugPrint("Erreur FMP pour $ticker: $e");
      return null;
    }
  }

  /// Tente de récupérer un prix via Yahoo Finance (API 'spark')
  Future<double?> _fetchFromYahoo(String ticker) async {
    final yahooUrl = Uri.parse(
        'https://query1.finance.yahoo.com/v7/finance/spark?symbols=$ticker&range=1d&interval=1d');
    try {
      final response = await _httpClient.get(yahooUrl, headers: {
        'User-Agent': 'Mozilla/5.0'
      }).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        debugPrint(
            'Erreur de l\'API Yahoo Finance (spark) pour $ticker: ${response.body}');
        return null;
      }

      final jsonData = jsonDecode(response.body);
      final List<dynamic>? results = jsonData['spark']?['result'];
      if (results != null && results.isNotEmpty) {
        final result = results[0];
        final String? resultSymbol = result['symbol'];
        final num? newPriceNum =
        result['response']?[0]?['meta']?['regularMarketPrice'];
        if (resultSymbol == ticker && newPriceNum != null) {
          return newPriceNum.toDouble();
        }
      }
      debugPrint("Yahoo (spark) n'a pas retourné de prix pour $ticker");
      return null;
    } catch (e) {
      debugPrint("Erreur http Yahoo (spark) pour $ticker: $e");
      return null;
    }
  }

  /// Recherche un ticker ou un ISIN
  Future<List<TickerSuggestion>> searchTicker(String query) async {
    // 1. Vérifier le cache (Cache de 24h pour la recherche)
    final timestamp = _searchCacheTimestamps[query];
    if (timestamp != null &&
        DateTime.now().difference(timestamp) < const Duration(hours: 24)) {
      return _searchCache[query] ?? [];
    }

    // 2. Appeler l'API de recherche Yahoo
    final url = Uri.parse(
        'https://query1.finance.yahoo.com/v1/finance/search?q=$query&lang=fr-FR&region=FR');
    try {
      debugPrint("🔍 Recherche de ticker: '$query' - URL: $url");
      final response = await _httpClient.get(url, headers: {
        'User-Agent': 'Mozilla/5.0'
      }).timeout(const Duration(seconds: 5));
      debugPrint("✅ Réponse reçue - Status: ${response.statusCode}");

      if (response.statusCode != 200) {
        debugPrint("❌ Erreur HTTP ${response.statusCode}: ${response.body}");
        throw Exception(
            "Erreur de l'API de recherche Yahoo: ${response.statusCode}");
      }

      final jsonData = jsonDecode(response.body);
      final List<dynamic> quotes = jsonData['quotes'] ?? [];
      final List<TickerSuggestion> suggestions = [];

      debugPrint("📊 ${quotes.length} résultats trouvés");

      for (final quote in quotes) {
        final String? ticker = quote['symbol'];
        final String? name = quote['longname'] ?? quote['shortname'];
        final String? exchange = quote['exchDisp'];
        if (ticker != null && name != null && exchange != null) {
          // Filtrer les résultats non pertinents
          if (quote['quoteType'] == 'EQUITY' ||
              quote['quoteType'] == 'ETF' ||
              quote['quoteType'] == 'CRYPTOCURRENCY') {
            suggestions
                .add(TickerSuggestion(ticker: ticker, name: name, exchange: exchange));
          }
        }
      }

      debugPrint("✅ ${suggestions.length} suggestions valides");
      // 3. Mettre en cache
      _searchCache[query] = suggestions;
      _searchCacheTimestamps[query] = DateTime.now();

      return suggestions;
    } on SocketException catch (e) {
      debugPrint("❌ Erreur réseau (SocketException) pour '$query': $e");
      debugPrint("💡 Vérifiez la permission INTERNET et la connexion réseau");
      return [];
    } on TimeoutException catch (e) {
      debugPrint("❌ Timeout lors de la recherche de '$query': $e");
      return [];
    } catch (e) {
      debugPrint("❌ Erreur lors de la recherche de ticker pour '$query': $e");
      return []; // Retourner une liste vide en cas d'erreur
    }
  }

  // --- NOUVEAU ---
  /// Vide les caches de prix et de recherche.
  void clearCache() {
    _priceCache.clear();
    _searchCache.clear();
    _searchCacheTimestamps.clear();
    debugPrint("ℹ️ Caches de l'ApiService vidés.");
  }

// --- SUPPRIMÉ ---
// La méthode getApiUsage() a été supprimée car l'endpoint n'existe pas.
}