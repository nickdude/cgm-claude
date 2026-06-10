import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../app/constants/app_assets.dart';
import '../../../../../core/widgets/app_surface.dart';
import '../../../dashboard/presentation/providers/cgm_dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/dashboard_theme.dart';
import '../../models/cgm_reading_model.dart';

class CgmReadingsScreen extends StatefulWidget {
  const CgmReadingsScreen({super.key});

  @override
  State<CgmReadingsScreen> createState() => _CgmReadingsScreenState();
}

class _CgmReadingsScreenState extends State<CgmReadingsScreen> {
  /// Newest-first copy of the shared provider's readings, for display + export.
  List<CgmReadingModel> _newestFirst(CGMDashboardProvider provider) {
    return [...provider.readings]
      ..sort((a, b) => b.readingAt.compareTo(a.readingAt));
  }

  bool _exporting = false;

  /// Escape a CSV field (wrap in quotes if it contains a comma/quote/newline).
  String _csv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Build a CSV of all readings and open the system share sheet
  /// (WhatsApp, email, etc.).
  Future<void> _exportCsv() async {
    if (_exporting) return;

    // Snapshot the shared provider's readings before any await.
    final readings = context.read<CGMDashboardProvider>().readings;

    setState(() => _exporting = true);
    try {
      if (readings.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No readings to export yet')),
          );
        }
        return;
      }

      // Oldest → newest reads more naturally in a spreadsheet.
      final sorted = [...readings]
        ..sort((a, b) => a.readingAt.compareTo(b.readingAt));

      final dateFmt = DateFormat('yyyy-MM-dd');
      final timeFmt = DateFormat('HH:mm');

      final buf = StringBuffer()
        ..writeln('Date,Time,Glucose (mg/dL),Trend,Timestamp (ISO)');
      for (final r in sorted) {
        // Use the reading's raw wall-clock fields (IST) — no timezone
        // conversion — so the export matches what the app displays.
        final wc = DateTime(
          r.readingAt.year,
          r.readingAt.month,
          r.readingAt.day,
          r.readingAt.hour,
          r.readingAt.minute,
          r.readingAt.second,
        );
        buf.writeln(
          '${dateFmt.format(wc)},'
          '${timeFmt.format(wc)},'
          '${r.glucoseValue.round()},'
          '${_csv(r.trend)},'
          '${r.readingAt.toIso8601String()}',
        );
      }

      final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'cgm_readings_$stamp.csv';
      final csv = buf.toString();

      // Web can't use dart:io / path_provider — share in-memory bytes there;
      // write a temp file on mobile (more reliable for the share sheet).
      final XFile xfile;
      if (kIsWeb) {
        xfile = XFile.fromData(
          Uint8List.fromList(utf8.encode(csv)),
          mimeType: 'text/csv',
          name: fileName,
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(csv);
        xfile = XFile(file.path, mimeType: 'text/csv', name: fileName);
      }

      await Share.shareXFiles(
        [xfile],
        subject: 'CGM Glucose Readings',
        text: 'My CGM glucose readings (${sorted.length} entries).',
      );
    } catch (e) {
      debugPrint('CSV export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not export: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
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
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: _exporting ? null : _exportCsv,
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: DashboardTheme.accent,
                    ),
                  )
                : const Icon(
                    Icons.ios_share_rounded,
                    color: DashboardTheme.textPrimary,
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: DashboardTheme.accent,
        backgroundColor: DashboardTheme.surface,
        onRefresh: () =>
            context.read<CGMDashboardProvider>().refresh(),
        child: Consumer<CGMDashboardProvider>(
          builder: (context, provider, _) {
            final readings = _newestFirst(provider);

            if (provider.isLoadingHistory && readings.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: DashboardTheme.accent),
              );
            }

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
