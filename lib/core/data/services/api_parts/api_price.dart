part of '../api_service.dart';

extension ApiServicePrice on ApiService {
  /// Récupère le prix pour un ticker.
  Future<PriceResult> getPriceImpl(String ticker) async {
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

      // 4. Si échec et que le ticker ressemble à un ISIN, tenter une recherche
      if (_isISIN(ticker)) {
        debugPrint(
            "🔍 Tentative de résolution ISIN pour $ticker via recherche...");
        try {
          final suggestions = await searchTicker(ticker);
          if (suggestions.isNotEmpty) {
            final bestMatch = suggestions.first;
            debugPrint(
                "✅ ISIN $ticker résolu en ${bestMatch.ticker} (${bestMatch.name})");

            // Appel récursif avec le nouveau ticker
            final resolvedResult = await getPrice(bestMatch.ticker);

            if (resolvedResult.price != null) {
              // On retourne le résultat mais avec le ticker ORIGINAL (l'ISIN)
              // pour que le SyncService puisse mapper correctement
              final finalResult = PriceResult(
                price: resolvedResult.price,
                currency: resolvedResult.currency,
                source: resolvedResult.source,
                ticker: ticker, // IMPORTANT: On garde l'ISIN ici
                errorDetails: resolvedResult.errorDetails,
              );
              _priceCache[ticker] = _CacheEntry(finalResult);
              return finalResult;
            }
          } else {
            errors['ISIN_Search'] = "Aucun ticker trouvé pour cet ISIN";
          }
        } catch (e) {
          errors['ISIN_Search'] = e.toString();
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

          if (resultSymbol != null &&
              resultSymbol.toUpperCase() == ticker.toUpperCase() &&
              newPriceNum != null) {
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

  bool _isISIN(String input) {
    return RegExp(r'^[A-Z]{2}[A-Z0-9]{9}[0-9]$').hasMatch(input);
  }
}
