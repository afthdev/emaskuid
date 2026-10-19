import 'package:emaskuid/data/models/json_utils.dart';

/// Full article from `/api/news/investor-id/detail`.
class NewsDetail {
  const NewsDetail({
    required this.title,
    required this.author,
    required this.publishedAt,
    required this.content,
    this.cover,
    this.tags,
  });

  final String title;
  final String author;
  final String publishedAt;
  final String content;
  final String? cover;
  final String? tags;

  factory NewsDetail.fromJson(Map<String, dynamic> json) {
    return NewsDetail(
      title: asString(json['title']),
      author: asString(json['author']),
      publishedAt: asString(json['publishedAt']),
      content: asString(json['content']),
      cover: json['cover']?.toString(),
      tags: json['tags']?.toString(),
    );
  }
}
