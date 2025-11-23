// lib/core/data/services/api_service.dart
// REMPLACEZ LE FICHIER COMPLET

// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:portefeuille/core/data/abstractions/i_settings.dart';
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
  // NOUVEAU : Code ISIN de l'actif (si disponible)
  final String? isin;
  // NOUVEAU : Prix actuel de l'actif
  final double? price;

  TickerSuggestion({
    required this.ticker,
    required this.name,
    required this.exchange,
    required this.currency,
    this.isin,
    this.price,
  });
}

// Objets de résultat pour un meilleur feedback
enum ApiSource { Fmp, Yahoo, Google, Cache, None }

class PriceResult {
  final double? price;
  final String currency; // Ex: "USD", "EUR"
  final ApiSource source;
  final String ticker;
  final Map<String, String>? errorDetails; // Source -> Error Message

  PriceResult({
    required this.price,
    required this.currency,
    required this.source,
    required this.ticker,
    this.errorDetails,
  });

  // Constructeur d'échec
  PriceResult.failure(this.ticker, {String? currency, this.errorDetails})
      : price = null,
        currency = currency ??
            'EUR', // Utilise la devise fournie, sinon EUR par défaut
        source = ApiSource.None;
}

/// Service responsable des appels réseau pour les données financières.
/// Gère la logique de cache et la stratégie FMP > Yahoo.
class ApiService {
  final ISettings _settings;
  // MODIFIÉ : Le cache stocke <String, _CacheEntry>
  final Map<String, _CacheEntry> _priceCache = {};
  final http.Client _httpClient;

  // Cache pour la recherche (24h)
  final Map<String, List<TickerSuggestion>> _searchCache = {};
  final Map<String, DateTime> _searchCacheTimestamps = {};

  // Cache pour les taux de change (24h)
  final Map<String, double> _exchangeRateCache = {};
  final Map<String, DateTime> _exchangeRateCacheTimestamps = {};

  ApiService({
    required ISettings settings,
    http.Client? httpClient,
  })  : _settings = settings,
        _httpClient = httpClient ?? http.Client();

  /// Récupère le prix pour un ticker.
  Future<PriceResult> getPrice(String ticker) async {
    final errors = <String, String>{};

    try {
      // 1. Vérifier le cache
      final cached = _priceCache[ticker];
      if (cached != null && !cached.isStale) {
        return cached.value; // Retourne le PriceResult mis en cache
      }

      // 2. Si le cache est vide ou obsolète, appeler le réseau
      PriceResult? result;
      
      // Récupérer l'ordre des services depuis les paramètres
      final serviceOrder = _settings.serviceOrder;
      
      for (final serviceName in serviceOrder) {
        try {
          switch (serviceName) {
            case 'FMP':
              if (_settings.hasFmpApiKey) {
                result = await _fetchFromFmp(ticker);
                if (result == null) errors['FMP'] = "Aucune donnée (ou erreur réseau)";
              } else {
                errors['FMP'] = "Clé API manquante";
              }
              break;
            case 'Yahoo':
              result = await _fetchFromYahoo(ticker);
              if (result == null) errors['Yahoo'] = "Aucune donnée (ou erreur réseau)";
              break;
            case 'Google':
              result = await _fetchFromGoogleFinance(ticker);
              if (result == null) errors['Google'] = "Scraping échoué";
              break;
          }
        } catch (e) {
          errors[serviceName] = e.toString();
        }

        // Si un résultat est trouvé, on arrête la boucle
        if (result != null) {
          _priceCache[ticker] = _CacheEntry(result);
          return result;
        }
      }

      // 5. Échec complet
      return PriceResult.failure(ticker,
          currency: _settings.baseCurrency, errorDetails: errors);
    } catch (e) {
      debugPrint(
          "⚠️ Erreur inattendue lors de la récupération du prix pour $ticker : $e");
      errors['System'] = e.toString();
      return PriceResult.failure(ticker,
          currency: _settings.baseCurrency, errorDetails: errors);
    }
  }

  /// Tente de récupérer un prix via FMP (Financial Modeling Prep)
  Future<PriceResult?> _fetchFromFmp(String ticker) async {
    if (!_settings.hasFmpApiKey) return null;
    final apiKey = _settings.fmpApiKey!;

    // Utiliser un proxy CORS sur web pour contourner les restrictions CORS
    final baseUrl = kIsWeb
        ? 'https://corsproxy.io/?https://financialmodelingprep.com'
        : 'https://financialmodelingprep.com';
    
    final uri = Uri.parse(
        '$baseUrl/api/v3/quote/$ticker?apikey=$apiKey');

    try {
      debugPrint("🔄 FMP: Récupération prix pour $ticker (web: $kIsWeb)");
      final response =
      await _httpClient.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final price = data[0]['price'];
          // FMP ne semble pas fournir la devise dans cet endpoint,
          // nous allons donc devoir la déduire ou la supposer.
          // Pour l'instant, supposons "USD" pour les tickers non-européens
          // et "EUR" pour ceux finissant par .PA, .F, .DE, etc.
          // C'est une simplification, Yahoo est meilleur pour ça.
          // NOTE : FMP fournit parfois la devise dans sa réponse.
          // Si elle est absente, on utilise la devise de base configurée par l'utilisateur.
          final currency =
              data[0]['currency'] ?? _settings.baseCurrency;

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

  /// Tente de récupérer un prix via Google Finance (Scraping)
  Future<PriceResult?> _fetchFromGoogleFinance(String ticker) async {
    // Mapping basique pour Google Finance
    String googleTicker = ticker;
    if (ticker.endsWith('.PA')) {
      googleTicker = '${ticker.replaceAll('.PA', '')}:EPA';
    } else if (!ticker.contains(':') && !ticker.contains('.')) {
      googleTicker = '$ticker:NASDAQ';
    }

    final url = 'https://www.google.com/finance/quote/$googleTicker';
    
    try {
      debugPrint("🔄 Google Finance: Tentative pour $googleTicker");
      final response = await _httpClient.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final body = response.body;
        // Recherche du pattern de prix (très fragile, dépend du DOM Google)
        // Pattern commun: <div class="YMlKec fxKbKc">123.45</div>
        final regExp = RegExp(r'<div class="YMlKec fxKbKc">([^<]+)</div>');
        final match = regExp.firstMatch(body);
        
        if (match != null) {
          String priceStr = match.group(1) ?? "";
          // Nettoyage du prix (enlever devises, virgules, etc)
          priceStr = priceStr.replaceAll(RegExp(r'[^\d.,]'), '');
          priceStr = priceStr.replaceAll(',', '.');
          
          final price = double.tryParse(priceStr);
          if (price != null) {
             return PriceResult(
              price: price,
              currency: _inferCurrency(ticker),
              source: ApiSource.Google,
              ticker: ticker,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur Google Finance pour $ticker: $e");
    }
    return null;
  }

  /// Tente de récupérer un prix via Yahoo Finance (API 'spark')
  /// Avec retry automatique (3 tentatives) et timeout adaptatif
  Future<PriceResult?> _fetchFromYahoo(String ticker) async {
    const maxRetries = 3;
    final timeouts = [
      const Duration(seconds: 5), // 1ère tentative: 5s
      const Duration(seconds: 8), // 2ème tentative: 8s
      const Duration(seconds: 12), // 3ème tentative: 12s
    ];

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final isLastAttempt = attempt == maxRetries - 1;
      final timeout = timeouts[attempt];

      try {
        debugPrint(
            "🔄 Yahoo Finance: Tentative ${attempt + 1}/$maxRetries pour $ticker (timeout: ${timeout.inSeconds}s, web: $kIsWeb)");

        // Utiliser un proxy CORS sur web pour contourner les restrictions CORS
        final baseUrl = kIsWeb
            ? 'https://corsproxy.io/?https://query1.finance.yahoo.com'
            : 'https://query1.finance.yahoo.com';
            
        final yahooUrl = Uri.parse(
            '$baseUrl/v7/finance/spark?symbols=$ticker&range=1d&interval=1d');

        final response = await _httpClient.get(yahooUrl,
            headers: {'User-Agent': 'Mozilla/5.0'}).timeout(timeout);

        if (response.statusCode != 200) {
          debugPrint(
              '❌ Yahoo Finance HTTP ${response.statusCode} pour $ticker');
          debugPrint('📄 Body: ${response.body}');

          // Retry sauf si 404 (ticker introuvable)
          if (response.statusCode == 404 || isLastAttempt) {
            return null;
          }

          // Attendre avant retry (délai exponentiel)
          await Future.delayed(Duration(seconds: attempt + 1));
          continue;
        }

        final jsonData = jsonDecode(response.body);
        final List<dynamic>? results = jsonData['spark']?['result'];

        if (results != null && results.isNotEmpty) {
          final result = results[0];
          final String? resultSymbol = result['symbol'];
          final num? newPriceNum =
          result['response']?[0]?['meta']?['regularMarketPrice'];
          final String currency =
              result['response']?[0]?['meta']?['currency'] ?? 'EUR';

          if (resultSymbol == ticker && newPriceNum != null) {
            debugPrint(
                "✅ Yahoo Finance: Prix $ticker = $newPriceNum $currency (tentative ${attempt + 1})");
            return PriceResult(
              price: newPriceNum.toDouble(),
              currency: currency,
              source: ApiSource.Yahoo,
              ticker: ticker,
            );
          }
        }

        debugPrint(
            "⚠️ Yahoo Finance: Pas de prix pour $ticker (tentative ${attempt + 1})");
        return null;
      } on TimeoutException {
        debugPrint(
            "⏱️ Timeout Yahoo Finance pour $ticker (tentative ${attempt + 1}/$maxRetries, ${timeout.inSeconds}s)");

        if (isLastAttempt) {
          debugPrint("❌ Échec final après $maxRetries tentatives (timeout)");
          return null;
        }

        // Attendre avant retry
        await Future.delayed(Duration(seconds: attempt + 1));
      } on SocketException catch (e) {
        debugPrint(
            "🌐 Erreur réseau Yahoo Finance pour $ticker (tentative ${attempt + 1}/$maxRetries)");
        debugPrint("📋 Détails: ${e.message}");

        if (isLastAttempt) {
          debugPrint("❌ Échec final après $maxRetries tentatives (réseau)");
          return null;
        }

        // Attendre avant retry
        await Future.delayed(Duration(seconds: attempt + 1));
      } catch (e) {
        debugPrint(
            "❌ Erreur Yahoo Finance pour $ticker (tentative ${attempt + 1}/$maxRetries)");
        debugPrint("📋 Détails: $e");

        if (isLastAttempt) {
          debugPrint("❌ Échec final après $maxRetries tentatives");
          return null;
        }

        // Attendre avant retry
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }

    return null;
  }

  /// Récupère le taux de change réel depuis l'API Frankfurter (BCE)
  ///
  /// Frankfurter fournit des taux de change officiels de la Banque Centrale Européenne
  /// 100% gratuit, pas de clé API requise, données fiables
  ///
  /// Exemple : _fetchExchangeRateFromFrankfurter('USD', 'EUR') → 0.92
  Future<double?> _fetchExchangeRateFromFrankfurter(
      String from, String to) async {
    final String baseUrl = kIsWeb
        ? 'https://corsproxy.io/?https://api.frankfurter.app'
        : 'https://api.frankfurter.app';

    final url =
    Uri.parse('$baseUrl/latest?from=$from&to=$to');

    try {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("💱 FRANKFURTER: Récupération taux $from → $to");
      debugPrint("🌐 URL: $url");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      final response =
      await _httpClient.get(url).timeout(const Duration(seconds: 5));

      debugPrint("📡 Réponse HTTP: ${response.statusCode}");

      if (response.statusCode != 200) {
        debugPrint("❌ Erreur Frankfurter (${response.statusCode})");
        debugPrint("📄 Body: ${response.body}");
        return null;
      }

      final jsonData = jsonDecode(response.body);
      debugPrint("📦 JSON reçu: $jsonData");

      final rates = jsonData['rates'];

      if (rates != null && rates[to] != null) {
        final rate = (rates[to] as num).toDouble();
        debugPrint("✅ SUCCÈS: 1 $from = $rate $to (source: BCE)");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        return rate;
      }

      debugPrint("⚠️ Frankfurter n'a pas retourné de taux pour $from→$to");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      return null;
    } on SocketException catch (e) {
      debugPrint("❌ ERREUR RÉSEAU Frankfurter pour $from→$to");
      debugPrint("📋 Détails: $e");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      return null;
    } on TimeoutException catch (e) {
      debugPrint("⏱️ TIMEOUT Frankfurter pour $from→$to (>5s)");
      debugPrint("📋 Détails: $e");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      return null;
    } catch (e) {
      debugPrint("❌ ERREUR INCONNUE Frankfurter pour $from→$to");
      debugPrint("📋 Détails: $e");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      return null;
    }
  }

  /// Récupère le taux de change entre deux devises.
  /// Utilise l'API Frankfurter (données BCE) avec mise en cache de 24h
  /// MODIFIÉ : Propage une exception si le taux n'est pas trouvé.
  Future<double> getExchangeRate(String from, String to) async {
    debugPrint("\n🔄 getExchangeRate appelé: $from → $to");
    // Si les devises sont identiques, le taux est 1
    if (from == to) {
      debugPrint("✅ Devises identiques ($from = $to), taux = 1.0");
      return 1.0;
    }

    // Vérifier le cache (24h)
    final cacheKey = '$from->$to';
    final cachedTimestamp = _exchangeRateCacheTimestamps[cacheKey];
    if (cachedTimestamp != null &&
        DateTime.now().difference(cachedTimestamp) <
            const Duration(hours: 24)) {
      final cachedRate = _exchangeRateCache[cacheKey];
      if (cachedRate != null) {
        final age = DateTime.now().difference(cachedTimestamp);
        debugPrint(
            "💾 CACHE HIT: Taux $from→$to = $cachedRate (âge: ${age.inMinutes}min)");
        return cachedRate;
      }
    }

    debugPrint("🌐 CACHE MISS: Appel API Frankfurter...");
    // Appeler Frankfurter
    final rate = await _fetchExchangeRateFromFrankfurter(from, to);
    if (rate != null) {
      // Mettre en cache
      _exchangeRateCache[cacheKey] = rate;
      _exchangeRateCacheTimestamps[cacheKey] = DateTime.now();
      debugPrint("💾 Taux $from→$to mis en cache: $rate (valide 24h)");
      return rate;
    }

    // --- ▼▼▼ CORRECTION : LOGIQUE OFFLINE ▼▼▼ ---
    debugPrint("⚠️ API a échoué pour $from→$to. Tentative d'utilisation du cache obsolète...");

    // Vérifier le cache SANS limite de temps (obsolète)
    final staleRate = _exchangeRateCache[cacheKey];
    if (staleRate != null) {
      debugPrint("💾 UTILISATION CACHE OBSOLÈTE: Taux $from→$to = $staleRate");
      return staleRate;
    }

    // Si AUCUNE donnée (ni fraîche, ni obsolète) n'existe
    debugPrint("❌ ERREUR CRITIQUE: Taux $from→$to indisponible (API échec ET cache vide).");
    throw Exception("Impossible d'obtenir le taux de change pour $from→$to");
    // --- ▲▲▲ FIN CORRECTION ▲▲▲
  }

  /// Recherche un ticker ou un ISIN
  Future<List<TickerSuggestion>> searchTicker(String query) async {
    final timestamp = _searchCacheTimestamps[query];
    if (timestamp != null &&
        DateTime.now().difference(timestamp) < const Duration(hours: 24)) {
      return _searchCache[query] ?? [];
    }

    // Utiliser un proxy CORS sur web pour contourner les restrictions CORS
    final baseUrl = kIsWeb
        ? 'https://corsproxy.io/?https://query1.finance.yahoo.com'
        : 'https://query1.finance.yahoo.com';
        
    final url = Uri.parse(
        '$baseUrl/v1/finance/search?q=$query&lang=fr-FR&region=FR');
    try {
      debugPrint("🔍 Recherche de ticker: '$query' - URL: $url (web: $kIsWeb)");
      final response = await _httpClient.get(url, headers: {
        'User-Agent': 'Mozilla/5.0'
      }).timeout(const Duration(seconds: 8));
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

      // OPTION C : Récupérer la devise réelle pour chaque résultat via getPrice()
      // On utilise Future.wait pour paralléliser les appels et accélérer la recherche
      final futures = <Future<TickerSuggestion?>>[];

      for (final quote in quotes) {
        final String? ticker = quote['symbol'];
        final String? name = quote['longname'] ?? quote['shortname'];
        final String? exchange = quote['exchDisp'];
        final String? isin = quote['isin'];

        if (ticker != null && name != null && exchange != null) {
          if (quote['quoteType'] == 'EQUITY' ||
              quote['quoteType'] == 'ETF' ||
              quote['quoteType'] == 'MUTUALFUND' ||
              quote['quoteType'] == 'INDEX' ||
              quote['quoteType'] == 'CRYPTOCURRENCY') {
            
            futures.add(() async {
              String currency = '???';
              double? price;
              try {
                final priceResult = await getPrice(ticker);
                if (priceResult.price != null) {
                  currency = priceResult.currency;
                  price = priceResult.price;
                  debugPrint("💱 Devise récupérée pour $ticker: $currency");
                }
              } catch (e) {
                debugPrint("⚠️ Impossible de récupérer la devise pour $ticker: $e");
              }

              return TickerSuggestion(
                ticker: ticker,
                name: name,
                exchange: exchange,
                currency: currency,
                isin: isin,
                price: price,
              );
            }());
          }
        }
      }

      final results = await Future.wait(futures);
      suggestions.addAll(results.whereType<TickerSuggestion>());

      debugPrint("✅ ${suggestions.length} suggestions valides avec devises");
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

  String _inferCurrency(String ticker) {
    if (ticker.endsWith('.PA') || ticker.endsWith('.DE') || ticker.endsWith('.AS') || ticker.endsWith('.BR') || ticker.endsWith('.MC')) {
      return 'EUR';
    }
    if (ticker.endsWith('.L')) {
      return 'GBP';
    }
    if (ticker.endsWith('.TO')) {
      return 'CAD';
    }
    if (ticker.endsWith('.SW')) {
      return 'CHF';
    }
    // Default to USD for US stocks (no suffix or NASDAQ/NYSE)
    return 'USD';
  }

  /// Vide les caches de prix, recherche et taux de change.
  void clearCache() {
    _priceCache.clear();
    _searchCache.clear();
    _searchCacheTimestamps.clear();
    _exchangeRateCache.clear();
    _exchangeRateCacheTimestamps.clear();
    debugPrint("ℹ️ Caches de l'ApiService vidés (prix, recherche, taux).");
  }
}