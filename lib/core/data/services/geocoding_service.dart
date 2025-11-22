import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Récupère les coordonnées (lat, lon) pour une ville donnée.
  /// Retourne null si non trouvé ou erreur.
  Future<Map<String, double>?> getCoordinates(String city) async {
    if (city.trim().isEmpty) return null;

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': city,
        'format': 'json',
        'limit': '1',
      });

      // Nominatim exige un User-Agent valide
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'MyInvestsApp/1.0 (contact@example.com)'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat']);
          final lon = double.tryParse(data[0]['lon']);

          if (lat != null && lon != null) {
            debugPrint('📍 Géocodage réussi pour $city: $lat, $lon');
            return {'lat': lat, 'lon': lon};
          }
        }
      } else {
        debugPrint('❌ Erreur Nominatim: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Exception Géocodage: $e');
    }
    return null;
  }
}
