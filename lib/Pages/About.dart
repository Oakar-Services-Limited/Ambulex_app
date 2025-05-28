import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ambulex_users/Components/MyDrawer.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  final List<FAQItem> faqs = [
    FAQItem(
      'What is Ambulex?',
      'Ambulex is an emergency response platform that connects users with immediate medical assistance and support for gender-based violence cases.',
    ),
    FAQItem(
      'How does it work?',
      'Simply press the emergency button for your specific need (Medical or GBV), and our team will immediately respond and dispatch the necessary help to your location.',
    ),
    FAQItem(
      'How much does it cost?',
      'Our service costs KES 200 per year. This subscription fee helps us maintain 24/7 emergency response capabilities and ensures quick assistance when you need it most.',
    ),
    FAQItem(
      'What does my subscription include?',
      '• 24/7 emergency response service\n• Access to medical emergency support\n• Gender-based violence response support\n• Real-time location tracking during emergencies\n• Priority dispatch of emergency services',
    ),
    FAQItem(
      'How do I pay for subscription?',
      'You can pay for your subscription through M-Pesa or other supported payment methods in the app. Once payment is confirmed, your subscription is activated immediately.',
    ),
    FAQItem(
      'Is my location data secure?',
      'Yes, we only access your location when you make an emergency request, and all data is encrypted and securely stored following strict privacy guidelines.',
    ),
    FAQItem(
      'What areas do you cover?',
      'We currently operate in major urban areas across Kenya. Contact our support team to verify coverage in your specific location.',
    ),
    FAQItem(
      'What happens in case of an emergency?',
      'When you press an emergency button, our system immediately:\n1. Captures your location\n2. Alerts our emergency response team\n3. Dispatches the nearest available help\n4. Provides real-time updates on assistance arrival',
    ),
    FAQItem(
      'Can I use the service for family members?',
      'Yes, you can set up separate accounts for family members, each with their own subscription. Contact us for family package options.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About Us',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAboutSection(),
              _buildContactSection(),
              _buildFAQSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Ambulex',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your Emergency Response Partner',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ambulex is dedicated to providing rapid emergency response services for medical emergencies and gender-based violence cases. Our mission is to ensure help is always just a button press away.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_support, color: Colors.blue, size: 28),
              const SizedBox(width: 8),
              Text(
                'Contact Us',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'We\'re here to help 24/7. Reach out to us through any of these channels:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          _buildContactGroup(
            'Emergency Hotline',
            [
              ContactItem(
                Icons.phone_in_talk,
                '0702898989',
                'tel:+254702898989',
                'Available 24/7 for emergencies',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactGroup(
            'Email Support',
            [
              ContactItem(
                Icons.email,
                'info@ambulexsolutions.org',
                'mailto:info@ambulexsolutions.org',
                'General inquiries and support',
              ),
              ContactItem(
                Icons.contact_mail,
                'petronila.mbithe@ambulexsolutions.org',
                'mailto:petronila.mbithe@ambulexsolutions.org',
                'Direct support line',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactGroup(
            'Office Hours',
            [
              ContactItem(
                Icons.access_time,
                'Monday - Friday: 8:00 AM - 6:00 PM',
                '',
                'For non-emergency inquiries',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactGroup(String title, List<ContactItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _buildContactItemEnhanced(item)).toList(),
      ],
    );
  }

  Widget _buildContactItemEnhanced(ContactItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: item.url.isNotEmpty ? () => launchUrl(Uri.parse(item.url)) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              Icon(item.icon, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.text,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.description.isNotEmpty)
                      Text(
                        item.description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              if (item.url.isNotEmpty)
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blue.shade300,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          ...faqs.map((faq) => _buildFAQItem(faq)).toList(),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              faq.answer,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactItem {
  final IconData icon;
  final String text;
  final String url;
  final String description;

  ContactItem(this.icon, this.text, this.url, this.description);
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem(this.question, this.answer);
}
