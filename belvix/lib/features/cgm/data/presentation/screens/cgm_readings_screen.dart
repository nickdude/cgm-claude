import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../../app/constants/app_assets.dart';
import '../../../../../core/widgets/app_surface.dart';
import '../../../dashboard/presentation/widgets/dashboard_theme.dart';
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

  /// Green when the reading sits in 70–180 mg/dL, alert colour otherwise.
  Color _statusColor(double v) =>
      (v >= 70 && v <= 180) ? DashboardTheme.accent : DashboardTheme.danger;

  /// arrow.svg points up-right (↗). Rotate it to reflect the trend, mapping
  /// the SDK trend levels to a 5-direction fan (↑ ↗ → ↘ ↓).
  double _trendAngle(String trend) {
    switch (trend.toLowerCase()) {
      case 'rising fast':
        return -math.pi / 4; // ↑
      case 'rising':
        return 0; // ↗
      case 'falling':
        return math.pi / 2; // ↘
      case 'falling fast':
        return 3 * math.pi / 4; // ↓
      default:
        return math.pi / 4; // → stable
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardTheme.screenBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: DashboardTheme.screenBg,
        centerTitle: false,
        titleSpacing: 16,
        toolbarHeight: 66,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Glucose History',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: DashboardTheme.textPrimary,
                height: 1.1,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Every reading, timestamped & trended',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: DashboardTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: DashboardTheme.accent,
        backgroundColor: DashboardTheme.surface,
        onRefresh: _refresh,
        child: FutureBuilder<List<CgmReadingModel>>(
          future: _readingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: DashboardTheme.accent),
              );
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
                    color: DashboardTheme.textMuted,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No CGM readings yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: DashboardTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your glucose readings will appear here with timestamp '
                    'and trend.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DashboardTheme.textSecondary),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: readings.length,
              itemBuilder: (context, index) {
                final reading = readings[index];
                final color = _statusColor(reading.glucoseValue);
                final formatter = DateFormat('MMM d, yyyy • h:mm a');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSurface(
                    padding: const EdgeInsets.all(16),
                    radius: DashboardTheme.radiusLg,
                    child: Row(
                      children: [
                        // Trend arrow badge — coloured by glucose range,
                        // pointed by the reading's trend.
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Transform.rotate(
                            angle: _trendAngle(reading.trend),
                            child: SvgPicture.asset(
                              AppAssets.trendArrow,
                              width: 22,
                              height: 22,
                              colorFilter: ColorFilter.mode(
                                color,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${reading.glucoseValue.toStringAsFixed(0)} '
                                'mg/dL',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: DashboardTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatter.format(reading.readingAt),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: DashboardTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            reading.trend,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
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
