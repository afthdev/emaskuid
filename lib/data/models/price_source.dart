import 'package:emaskuid/data/models/json_utils.dart';

/// A toko / price source (`/api/prices`).
class PriceSource {
  const PriceSource({
    required this.name,
    required this.displayName,
    this.logo = '',
    this.favicon,
    this.cover,
    this.url = '',
    this.urlHomepage,
  });

  final String name;
  final String displayName;
  final String logo;
  final String? favicon;
  final String? cover;
  final String url;
  final String? urlHomepage;

  factory PriceSource.fromJson(Map<String, dynamic> json) {
    return PriceSource(
      name: asString(json['name']),
      displayName: asString(json['displayName'], asString(json['name'])),
      logo: asString(json['logo']),
      favicon: json['favicon']?.toString(),
      cover: json['cover']?.toString(),
      url: asString(json['url']),
      urlHomepage: json['urlHomepage']?.toString(),
    );
  }
}
