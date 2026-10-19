import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:emaskuid/controllers/news_controller.dart';
import 'package:emaskuid/data/models/models.dart';

class NewsDetailPage extends StatefulWidget {
  const NewsDetailPage({super.key, required this.item});

  final NewsItem item;

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late Future<NewsDetail> _future = Get.find<NewsController>().detail(
    widget.item.url,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Berita')),
      body: FutureBuilder<NewsDetail>(
        future: _future,
        builder: (context, snapshot) {
          final detail = snapshot.data;
          final loading = snapshot.connectionState == ConnectionState.waiting;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (widget.item.cover != null && widget.item.cover!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: widget.item.cover!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: scheme.surfaceContainerHighest),
                      errorWidget: (_, _, _) =>
                          Container(color: scheme.surfaceContainerHighest),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                detail?.title ?? widget.item.title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.public_rounded,
                    size: 15,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.item.displayName,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (detail?.author != null && detail!.author.isNotEmpty) ...[
                    Text(
                      ' • ',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    Text(
                      detail.author,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    detail?.publishedAt.isNotEmpty == true
                        ? detail!.publishedAt
                        : widget.item.publishedAt,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                _errorBox(context, snapshot.error.toString())
              else
                SelectableText(
                  (detail?.content ?? '').trim().isEmpty
                      ? widget.item.summary
                      : detail!.content.trim(),
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              if (detail?.tags != null && detail!.tags!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  detail.tags!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _errorBox(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: scheme.error),
              const SizedBox(width: 8),
              const Text(
                'Gagal memuat isi berita',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.item.summary, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _future = Get.find<NewsController>().detail(widget.item.url);
            }),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
