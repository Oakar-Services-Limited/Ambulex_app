import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PackageDetail extends StatelessWidget {
  const PackageDetail({super.key, required this.package});

  final Map<String, dynamic> package;

  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('lite') || n.contains('basic')) return Icons.bolt;
    if (n.contains('plus')) return Icons.add_circle;
    if (n.contains('prime')) return Icons.star;
    if (n.contains('total') || n.contains('golden')) return Icons.diamond;
    if (n.contains('careride')) return Icons.directions_car;
    return Icons.workspace_premium;
  }

  static Color _primaryColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('lite')) return Colors.green.shade600;
    if (n.contains('plus')) return Colors.blue.shade600;
    if (n.contains('prime')) return Colors.purple.shade600;
    if (n.contains('total')) return Colors.orange.shade600;
    if (n.contains('golden')) return Colors.amber.shade700;
    if (n.contains('careride')) return Colors.red.shade600;
    return Colors.blue.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final name = package['name'] ?? 'Package';
    final price = package['price'] ?? 'N/A';
    final features = package['features'] as List<dynamic>? ?? [];
    final primary = _primaryColor(name);

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
        foregroundColor: Colors.white,
        backgroundColor: primary,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primary.withOpacity(0.12), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primary.withOpacity(0.15),
                                primary.withOpacity(0.06),
                                Colors.white,
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_iconFor(name), size: 48, color: primary),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                name,
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                price,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                              Text(
                                'per year',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (features.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: primary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'What\'s included',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: features.map<Widget>((f) {
                                final text = f is Map ? (f['name'] ?? f.toString()) : f.toString();
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.check_circle, size: 20, color: primary.withOpacity(0.8)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          text,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey.shade800,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, package),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: Text(
                      'Subscribe - $price',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
