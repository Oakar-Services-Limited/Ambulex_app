import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Pages/ReadNews.dart';

class NewsBar extends StatelessWidget {
  final String id;
  final String title;
  final String type;
  final String description;
  final String keywords;
  final String link;
  final String image;
  final String publishedAt;

  const NewsBar({
    super.key,
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.keywords,
    required this.link,
    required this.image,
    required this.publishedAt,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> tagList = keywords.isNotEmpty
        ? keywords
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : [];
    String formattedDate = '';
    if (publishedAt.isNotEmpty) {
      try {
        final date = DateTime.parse(publishedAt);
        formattedDate = 'Published: ' +
            DateFormat('M/d/yyyy').format(date) +
            ' at ' +
            DateFormat('hh:mm a').format(date) +
            ' hrs';
      } catch (e) {
        formattedDate = '';
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Card(
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReadNews(id: id)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: image.isNotEmpty
                      ? Image.network(
                          image,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image,
                              size: 48, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (tagList.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: tagList
                              .map((tag) => Chip(
                                    label: Text(tag,
                                        style: const TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.grey[100],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ))
                              .toList(),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (type.isNotEmpty)
                            Chip(
                              label: Text(type,
                                  style: const TextStyle(color: Colors.white)),
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (formattedDate.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
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
      ),
    );
  }

  // Try to extract a date from the content if possible (fallback: empty string)
  static String _extractDate(String content) {
    // This is a placeholder. You may want to pass a date field from the API instead.
    // If you have a published_at or created_at field, use it instead of this function.
    return '';
  }
}
