import 'dart:ui';

enum InstitutionType {
  Bank,
  Broker,
  CryptoExchange,
  Wallet,
  Other
}

class InstitutionMetadata {
  final String id;
  final String name;
  final InstitutionType type;
  final String country;
  final String logoAsset;
  final Color primaryColor;
  final String website;
  final List<String> defaultAccountTypes;

  InstitutionMetadata({
    required this.id,
    required this.name,
    required this.type,
    required this.country,
    required this.logoAsset,
    required this.primaryColor,
    required this.website,
    required this.defaultAccountTypes,
  });

  factory InstitutionMetadata.fromJson(Map<String, dynamic> json) {
    return InstitutionMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      type: _parseType(json['type'] as String),
      country: json['country'] as String,
      logoAsset: json['logoAsset'] as String,
      primaryColor: _parseColor(json['primaryColor'] as String),
      website: json['website'] as String,
      defaultAccountTypes: (json['defaultAccountTypes'] as List).cast<String>(),
    );
  }

  static InstitutionType _parseType(String type) {
    return InstitutionType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => InstitutionType.Other,
    );
  }

  static Color _parseColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
