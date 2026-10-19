import 'package:emaskuid/data/models/json_utils.dart';

/// A news row from `/api/news/investor-id`.
class NewsItem {
  const NewsItem({
    required this.title,
    required this.url,
    required this.publishedAt,
    required this.summary,
    required this.category,
    required this.displayName,
    this.logo,
    this.cover,
    this.urlHomepage,
  });

  final String title;
  final String url;
  final String publishedAt;
  final String summary;
  final String category;
  final String displayName;
  final String? logo;
  final String? cover;
  final String? urlHomepage;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      title: asString(json['title']),
      url: asString(json['url']),
      publishedAt: asString(json['publishedAt']),
      summary: asString(json['summary']),
      category: asString(json['category']),
      displayName: asString(json['displayName'], 'Investor.id'),
      logo: json['logo']?.toString(),
      cover: json['cover']?.toString(),
      urlHomepage: json['urlHomepage']?.toString(),
    );
  }
}
