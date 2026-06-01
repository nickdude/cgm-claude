import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F4),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Discover',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(child: DiscoverTabContent()),
      ),
    );
  }
}

class DiscoverTabContent extends StatelessWidget {
  const DiscoverTabContent({super.key});

  // Content sourced from belvixdiagnosticindia.com — each card opens the
  // original article on the website.
  static const List<DiscoverCardData> _cards = [
    DiscoverCardData(
      imagePath: 'assets/images/discover/discover-1.png',
      title: 'CGMS365',
      url: 'https://belvixdiagnosticindia.com/cgms365',
      description:
          'CGMS365 is an advanced continuous glucose monitoring system that '
          'delivers accurate, real-time glucose insights. With a 15-day, '
          'calibration-free sensor and a compact all-in-one design, it pairs '
          'over Bluetooth with iOS, Android and HarmonyOS to make everyday '
          'diabetes management simpler and smarter.',
    ),
    DiscoverCardData(
      imagePath: 'assets/images/discover/discover-2.jpg',
      title: 'CGM and Modern Diabetes Care',
      url: 'https://belvixdiagnosticindia.com/f/cgm-and-modern-diabetes-care',
      description:
          'Continuous glucose monitoring is at the heart of modern diabetes '
          'care. Instead of occasional finger-prick readings, CGM reveals '
          'real-time glucose trends that help guide everyday decisions around '
          'food, activity and medication — for tighter control with less '
          'guesswork.',
    ),
    DiscoverCardData(
      imagePath: 'assets/images/discover/discover-3.jpg',
      title: 'Preventive Healthcare Starts with Regular Health Monitoring',
      url:
          'https://belvixdiagnosticindia.com/f/'
          'preventive-healthcare-starts-with-regular-health-monitoring',
      description:
          'Prevention begins with awareness. Regular health monitoring — of '
          'glucose, blood pressure and other key markers — helps you catch '
          'changes early and stay ahead of chronic conditions, putting you in '
          'control of your long-term health.',
    ),
    DiscoverCardData(
      // Reusing an existing image for now.
      imagePath: 'assets/images/discover/discover-1.png',
      title: 'How Continuous Glucose Monitoring is Changing Diabetes Care',
      url:
          'https://belvixdiagnosticindia.com/f/'
          'how-continuous-glucose-monitoring-is-changing-diabetes-care',
      description:
          'CGM is transforming diabetes care by replacing snapshot readings '
          'with a continuous stream of data. Seeing how glucose responds to '
          'meals, exercise and sleep uncovers patterns, reduces guesswork and '
          'enables timely, personalized decisions for better outcomes.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in _cards)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _DiscoverCard(
              item: item,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DiscoverDetailScreen(item: item),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Opens the article on the website in the device browser.
Future<void> _openArticle(BuildContext context, String url) async {
  final uri = Uri.parse(url);

  var opened = false;
  try {
    // Prefer an external browser; fall back to the platform default if the
    // external launch isn't available.
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (_) {
    opened = false;
  }

  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the article right now')),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.public_rounded, size: 15, color: Color(0xFF737983)),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            'belvixdiagnosticindia.com',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF737983),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({required this.item, required this.onTap});

  final DiscoverCardData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3E3E3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.42,
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(
                      color: Color(0xFFEFF1F4),
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Color(0xFF9AA1AB),
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _SourceRow(),
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

class DiscoverDetailScreen extends StatelessWidget {
  const DiscoverDetailScreen({super.key, required this.item});

  final DiscoverCardData item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F4),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF111111),
            size: 22,
          ),
        ),
        title: const Text(
          'Discover',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3E3E3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: AspectRatio(
                  aspectRatio: 1.42,
                  child: Image.asset(item.imagePath, fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 24,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _SourceRow(),
                    const SizedBox(height: 16),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF4E5561),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openArticle(context, item.url),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Read full article'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111111),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
    );
  }
}

class DiscoverCardData {
  const DiscoverCardData({
    required this.imagePath,
    required this.title,
    required this.url,
    required this.description,
  });

  final String imagePath;
  final String title;

  /// Original article URL on belvixdiagnosticindia.com.
  final String url;
  final String description;
}
