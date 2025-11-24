// lib/core/data/services/api_service.dart

// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:portefeuille/core/data/abstractions/i_settings.dart';
import 'dart:convert';

part 'api_parts/api_types.dart';
part 'api_parts/api_price.dart';
part 'api_parts/api_search.dart';
part 'api_parts/api_exchange.dart';

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

  /// Vide les caches de prix, recherche et taux de change.
  void clearCache() {
    _priceCache.clear();
    _searchCache.clear();
    _searchCacheTimestamps.clear();
    _exchangeRateCache.clear();
    _exchangeRateCacheTimestamps.clear();
    debugPrint("ℹ️ Caches de l'ApiService vidés (prix, recherche, taux).");
  }

  /// Récupère le prix pour un ticker.
  Future<PriceResult> getPrice(String ticker) => getPriceImpl(ticker);

  /// Recherche un ticker ou un ISIN
  Future<List<TickerSuggestion>> searchTicker(String query) => searchTickerImpl(query);

  /// Récupère le taux de change entre deux devises.
  Future<double> getExchangeRate(String from, String to) => getExchangeRateImpl(from, to);
}
