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
  // MODIFIÉ : Le cache stocke le PriceResult complet
  final PriceResult value;
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
  // NOUVEAU : Ajouter la devise à la suggestion de recherche
  final String currency;

  TickerSuggestion({
    required this.ticker,
    required this.name,
    required this.exchange,
    required this.currency,
  });
}

// Objets de résultat pour un meilleur feedback
enum ApiSource { Fmp, Yahoo, Cache, None }

class PriceResult {
  final double? price;
  final String currency; // Ex: "USD", "EUR"
  final ApiSource source;
  final String ticker;

  PriceResult({
    required this.price,
    required this.currency,
    required this.source,
    required this.ticker,
  });

  // Constructeur d'échec
  PriceResult.failure(this.ticker)
      : price = null,
        currency = 'EUR', // Devise par défaut en cas d'échec
        source = ApiSource.None;
}

/// Service responsable des appels réseau pour les données financières.
/// Gère la logique de cache et la stratégie FMP > Yahoo.
class ApiService {
  final SettingsProvider _settingsProvider;
  // MODIFIÉ : Le cache stocke <String, _CacheEntry>
  final Map<String, _CacheEntry> _priceCache = {};
  final http.Client _httpClient;

  // Cache pour la recherche (24h)
  final Map<String, List<TickerSuggestion>> _searchCache = {};
  final Map<String, DateTime> _searchCacheTimestamps = {};

  ApiService({
    required SettingsProvider settingsProvider,
    http.Client? httpClient,
  })  : _settingsProvider = settingsProvider,
        _httpClient = httpClient ?? http.Client();

  /// Récupère le prix pour un ticker.
  Future<PriceResult> getPrice(String ticker) async {
    try {
      // 1. Vérifier le cache
      final cached = _priceCache[ticker];
      if (cached != null && !cached.isStale) {
        return cached.value; // Retourne le PriceResult mis en cache
      }

      // 2. Si le cache est vide ou obsolète, appeler le réseau
      PriceResult? result;
      final bool hasFmpKey = _settingsProvider.hasFmpApiKey;

      if (hasFmpKey) {
        result = await _fetchFromFmp(ticker);
        if (result != null) {
          _priceCache[ticker] = _CacheEntry(result);
          return result;
        }
      }

      // 3. Stratégie 2 : Yahoo (Fallback ou si FMP n'a pas de clé)
      result = await _fetchFromYahoo(ticker);

      // 4. Mettre à jour le cache et retourner
      if (result != null) {
        _priceCache[ticker] = _CacheEntry(result);
        return result;
      }

      // 5. Échec complet
      return PriceResult.failure(ticker);
    } catch (e) {
      debugPrint(
          "⚠️ Erreur inattendue lors de la récupération du prix pour $ticker : $e");
      return PriceResult.failure(ticker);
    }
  }

  /// Tente de récupérer un prix via FMP (Financial Modeling Prep)
  Future<PriceResult?> _fetchFromFmp(String ticker) async {
    if (!_settingsProvider.hasFmpApiKey) return null;
    final apiKey = _settingsProvider.fmpApiKey!;

    final uri = Uri.parse(
        'https://financialmodelingprep.com/api/v3/quote/$ticker?apikey=$apiKey');

    try {
      final response =
      await _httpClient.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final price = data[0]['price'];
          // FMP ne semble pas fournir la devise dans cet endpoint,
          // nous allons donc devoir la déduire ou la supposer.
          // Pour l'instant, supposons "USD" pour les tickers non-européens
          // et "EUR" pour ceux finissant par .PA, .F, .DE, etc.
          // C'est une simplification, Yahoo est meilleur pour ça.
          // NOTE : Pour ce projet, nous allons simplifier et utiliser "EUR" par défaut
          // si FMP ne le fournit pas.
          final currency = data[0]['currency'] ?? 'EUR'; // Simplification

          if (price is num) {
            return PriceResult(
              price: price.toDouble(),
              currency: currency,
              source: ApiSource.Fmp,
              ticker: ticker,
            );
          }
        }
      }
      debugPrint(
          "Erreur FMP pour $ticker (Status: ${response.statusCode}): ${response.body}");
      return null;
    } catch (e) {
      debugPrint("Erreur FMP pour $ticker: $e");
      return null;
    }
  }

  /// Tente de récupérer un prix via Yahoo Finance (API 'spark')
  Future<PriceResult?> _fetchFromYahoo(String ticker) async {
    final yahooUrl = Uri.parse(
        'https://query1.finance.yahoo.com/v7/finance/spark?symbols=$ticker&range=1d&interval=1d');
    try {
      final response = await _httpClient.get(yahooUrl,
          headers: {'User-Agent': 'Mozilla/5.0'}).timeout(
          const Duration(seconds: 8));

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
        // NOUVEAU : Récupérer la devise
        final String currency =
            result['response']?[0]?['meta']?['currency'] ?? 'EUR';

        if (resultSymbol == ticker && newPriceNum != null) {
          return PriceResult(
            price: newPriceNum.toDouble(),
            currency: currency,
            source: ApiSource.Yahoo,
            ticker: ticker,
          );
        }
      }
      debugPrint("Yahoo (spark) n'a pas retourné de prix pour $ticker");
      return null;
    } catch (e) {
      debugPrint("Erreur http Yahoo (spark) pour $ticker: $e");
      return null;
    }
  }

  // --- NOUVELLE MÉTHODE ---
  /// Récupère le taux de change entre deux devises.
  /// (Pour l'instant, simule un taux fixe pour les tests)
  Future<double> getExchangeRate(String from, String to) async {
    // Si les devises sont identiques, le taux est 1
    if (from == to) return 1.0;

    // Simulation pour le développement
    // TODO: Remplacer par un appel API réel (ex: FMP ou Yahoo)
    if (from == 'USD' && to == 'EUR') {
      debugPrint("API: Taux de change SIMULÉ USD->EUR: 0.92");
      return 0.92;
    }
    if (from == 'EUR' && to == 'USD') {
      debugPrint("API: Taux de change SIMULÉ EUR->USD: 1.08");
      return 1.08;
    }

    debugPrint(
        "API: Taux de change SIMULÉ pour $from->$to: 1.0 (non géré)");
    // Retourne 1.0 si la paire n'est pas gérée par la simulation
    return 1.0;
  }
  // --- FIN NOUVELLE MÉTHODE ---

  /// Recherche un ticker ou un ISIN
  Future<List<TickerSuggestion>> searchTicker(String query) async {
    final timestamp = _searchCacheTimestamps[query];
    if (timestamp != null &&
        DateTime.now().difference(timestamp) < const Duration(hours: 24)) {
      return _searchCache[query] ?? [];
    }

    final url = Uri.parse(
        'https://query1.finance.yahoo.com/v1/finance/search?q=$query&lang=fr-FR&region=FR');
    try {
      debugPrint("🔍 Recherche de ticker: '$query' - URL: $url");
      final response = await _httpClient.get(url,
          headers: {'User-Agent': 'Mozilla/5.0'}).timeout(
          const Duration(seconds: 5));
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
        // NOUVEAU : Récupérer la devise de l'actif
        // Note : L'API 'search' ne fournit pas la devise. Nous devons la déduire
        // ou la laisser vide. Pour ce projet, nous allons la laisser vide
        // et le formulaire de transaction la demandera si besoin.
        // ---
        // MISE A JOUR : Tentons de la récupérer depuis 'currency' si elle existe
        final String currency = quote['currency'] ?? '???';

        if (ticker != null && name != null && exchange != null) {
          if (quote['quoteType'] == 'EQUITY' ||
              quote['quoteType'] == 'ETF' ||
              quote['quoteType'] == 'CRYPTOCURRENCY') {
            suggestions.add(TickerSuggestion(
              ticker: ticker,
              name: name,
              exchange: exchange,
              currency: currency, // <-- MODIFIÉ
            ));
          }
        }
      }

      debugPrint("✅ ${suggestions.length} suggestions valides");
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
      return [];
    }
  }

  /// Vide les caches de prix et de recherche.
  void clearCache() {
    _priceCache.clear();
    _searchCache.clear();
    _searchCacheTimestamps.clear();
    debugPrint("ℹ️ Caches de l'ApiService vidés.");
  }
}