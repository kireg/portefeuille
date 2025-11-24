part of '../api_service.dart';

extension ApiServiceSearch on ApiService {
  /// Recherche un ticker ou un ISIN
  Future<List<TickerSuggestion>> searchTickerImpl(String query) async {
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
}
