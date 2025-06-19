import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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
            DateFormat('d MMM yyyy').format(date) +
            ' at ' +
            DateFormat('hh:mm a').format(date);
      } catch (e) {
        formattedDate = '';
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReadNews(id: id)),
          );
        },
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: image.isNotEmpty
                      ? Image.network(
                          image,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image,
                              size: 40, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.blue.shade700,
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
                                            style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.blue)),
                                        backgroundColor: Colors.blue.shade50,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 14, color: Colors.blueGrey),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (type.isNotEmpty)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              type,
                              style: GoogleFonts.poppins(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
