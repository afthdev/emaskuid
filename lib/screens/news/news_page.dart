import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:emaskuid/controllers/news_controller.dart';
import 'package:emaskuid/core/testing/test_ids.dart';
import 'package:emaskuid/data/models/models.dart';
import 'package:emaskuid/widgets/widgets.dart';
import 'package:emaskuid/screens/news/news_detail_page.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final news = Get.find<NewsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Berita Emas')),
      body: Obx(
        () => AsyncStateView(
          loading: news.loading.value,
          hasData: news.items.isNotEmpty,
          error: news.error.value,
          emptyMessage: 'Belum ada berita.',
          onRetry: news.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: news.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, i) => _newsCard(context, news.items[i]),
          ),
        ),
      ),
    );
  }

  Future<void> _openInBrowser(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.isEmpty) {
      Get.snackbar('Gagal', 'Tautan berita tidak valid.');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      Get.snackbar('Gagal', 'Tidak bisa membuka browser.');
    }
  }

  Widget _newsCard(BuildContext context, NewsItem item) {
    final scheme = Theme.of(context).colorScheme;
    final hasCover = item.cover != null && item.cover!.isNotEmpty;

    return SemId(
      TestIds.newsItem(item.url),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openInBrowser(context, item.url),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasCover)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: item.cover!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: scheme.surfaceContainerHighest),
                    errorWidget: (_, _, _) => Container(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: scheme.outline,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Pill(
                          text: item.category.isEmpty
                              ? 'Berita'
                              : item.category,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.publishedAt,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    if (item.summary.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.public_rounded, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SemId(
                          TestIds.newsSummaryButton(item.url),
                          child: TextButton.icon(
                            onPressed: () =>
                                Get.to(() => NewsDetailPage(item: item)),
                            icon: const Icon(Icons.article_outlined, size: 16),
                            label: const Text('Ringkasan'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
