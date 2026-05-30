import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/cgm_reading_model.dart';
import '../../repository/cgm_reading_repository_impl.dart';

class CgmReadingsScreen extends StatefulWidget {
  const CgmReadingsScreen({super.key});

  @override
  State<CgmReadingsScreen> createState() => _CgmReadingsScreenState();
}

class _CgmReadingsScreenState extends State<CgmReadingsScreen> {
  final CgmReadingRepository _repository = CgmReadingRepository();

  late Future<List<CgmReadingModel>> _readingsFuture;

  @override
  void initState() {
    super.initState();
    _readingsFuture = _loadReadings();
  }

  Future<List<CgmReadingModel>> _loadReadings() async {
    final readings = await _repository.listReadings();
    readings.sort((a, b) => b.readingAt.compareTo(a.readingAt));
    return readings;
  }

  Future<void> _refresh() async {
    setState(() {
      _readingsFuture = _loadReadings();
    });

    await _readingsFuture;
  }

  Color _trendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'rising':
      case 'rising fast':
        return const Color(0xFFEA580C);
      case 'falling':
      case 'falling fast':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF2563EB);
    }
  }

  IconData _trendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'rising':
      case 'rising fast':
        return Icons.trending_up;
      case 'falling':
      case 'falling fast':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Data'),
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<CgmReadingModel>>(
          future: _readingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final readings = snapshot.data ?? const <CgmReadingModel>[];

            if (readings.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Icon(
                    Icons.insights_outlined,
                    size: 72,
                    color: Color(0xFFCBD5E1),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No CGM readings yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your glucose readings will appear here with timestamp and trend.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: readings.length,
              itemBuilder: (context, index) {
                final reading = readings[index];
                final trendColor = _trendColor(reading.trend);
                final formatter = DateFormat('MMM d, yyyy • h:mm a');

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: trendColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          _trendIcon(reading.trend),
                          color: trendColor,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${reading.glucoseValue.toStringAsFixed(0)} mg/dL',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatter.format(reading.readingAt),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: trendColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          reading.trend,
                          style: TextStyle(
                            color: trendColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
