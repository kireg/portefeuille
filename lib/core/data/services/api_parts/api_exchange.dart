part of '../api_service.dart';

extension ApiServiceExchange on ApiService {
  /// Récupère le taux de change réel depuis l'API Frankfurter (BCE)
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
  Future<double> getExchangeRateImpl(String from, String to) async {
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
}
