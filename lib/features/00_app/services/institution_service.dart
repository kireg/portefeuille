import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:portefeuille/core/data/models/institution_metadata.dart';

class InstitutionService {
  List<InstitutionMetadata> _institutions = [];

  List<InstitutionMetadata> get institutions => _institutions;

  Future<void> loadInstitutions() async {
    try {
      final String response = await rootBundle.loadString('assets/data/institutions.json');
      final List<dynamic> data = json.decode(response);
      _institutions = data.map((json) => InstitutionMetadata.fromJson(json)).toList();
    } catch (e) {
      // En cas d'erreur (ex: fichier non trouvé), on garde une liste vide
      // ou on pourrait logger l'erreur
      _institutions = [];
    }
  }
  
  List<InstitutionMetadata> search(String query) {
    if (query.isEmpty) return _institutions;
    final lowerQuery = query.toLowerCase();
    return _institutions.where((inst) => 
      inst.name.toLowerCase().contains(lowerQuery) || 
      inst.id.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}
