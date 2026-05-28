import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../exercise/presentation/providers/exercise_provider.dart';
import '../../../../finger_blood/presentation/providers/finger_blood_provider.dart';
import '../../../../finger_blood/presentation/screens/finger_blood_screen.dart';
import '../../../../food/presentation/providers/food_provider.dart';
import '../../../../insulin/presentation/providers/insulin_provider.dart';
import '../../../../insulin/presentation/screens/insulin_screen.dart';
import '../../../connect/presentation/providers/cgm_provider.dart';
import '../../../connect/presentation/screens/device_management_screen.dart';
import '../providers/cgm_dashboard_provider.dart';
import '../widgets/dashboard_theme.dart';
import '../widgets/day_snapshot.dart';
import '../widgets/glucose_alert_card.dart';
import '../widgets/glucose_chart.dart';
import '../widgets/glucose_chart_card.dart';
import '../widgets/glucose_gauge.dart';
import '../widgets/metabolic_score_card.dart';
import '../widgets/reveal.dart';
import '../widgets/sensor_status_card.dart';
import '../widgets/sync_progress_card.dart';
import '../widgets/week_score_strip.dart';

/// Production CGM dashboard.
///
/// The widget tree composes purpose-built dashboard sub-widgets in the
/// order shown in `figma-screenshot/dashboard/`. All data routes through
/// the existing providers — only UI/UX is touched here.
///
/// The top week strip drives a `_selectedDay` state. All visible
/// metrics (gauge, score, chart, stats) recompute from a [DaySnapshot]
/// of the readings for that day.
class CGMDashboardScreen extends StatefulWidget {
  const CGMDashboardScreen({super.key});

  @override
  State<CGMDashboardScreen> createState() => _CGMDashboardScreenState();
}

class _CGMDashboardScreenState extends State<CGMDashboardScreen> {
  CGMDashboardProvider? _dashboardProvider;

  /// Midnight of the day the user is currently viewing. Defaults to today.
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<CGMDashboardProvider>().startRealtimeUpdates();
      context.read<CGMProvider>().fetchDevices();
      context.read<FoodProvider>().fetchFoods();
      context.read<ExerciseProvider>().fetchExercises();
      context.read<InsulinProvider>().fetchInsulins();
      context.read<FingerBloodProvider>().fetchFingerBloods();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dashboardProvider = context.read<CGMDashboardProvider>();
  }

  @override
  void dispose() {
    _dashboardProvider?.stopUpdates();
    super.dispose();
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardTheme.screenBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: DashboardTheme.screenBg,
        title: const Text(
          'CGM Dashboard',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: DashboardTheme.textPrimary,
          ),
        ),
        actions: [
          _AppBarIconButton(
            tooltip: 'Devices',
            icon: Icons.medical_services_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeviceManagementScreen(),
                ),
              );
            },
          ),
          _AppBarIconButton(
            tooltip: 'Notifications',
            icon: Icons.notifications_none_rounded,
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => const _NotificationsSheet(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: DashboardTheme.accent,
        backgroundColor: DashboardTheme.surface,
        onRefresh: () async {
          await Future.wait([
            context.read<CGMProvider>().fetchDevices(),
            context.read<CGMDashboardProvider>().refresh(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            DashboardTheme.space20,
            DashboardTheme.space8,
            DashboardTheme.space20,
            DashboardTheme.space24,
          ),
          child: Column(
            children: [
              Reveal(
                delayMs: 0,
                child: _WeekStripSection(
                  selectedDay: _selectedDay,
                  onDaySelected: _onDaySelected,
                ),
              ),
              const SizedBox(height: DashboardTheme.space16),
              Reveal(
                delayMs: 60,
                child: _GaugeSection(selectedDay: _selectedDay),
              ),
              const SizedBox(height: DashboardTheme.space16),
              Reveal(
                delayMs: 120,
                child: _ScoreSection(selectedDay: _selectedDay),
              ),
              const SizedBox(height: DashboardTheme.space16),
              Reveal(
                delayMs: 160,
                child: _AlertSection(selectedDay: _selectedDay),
              ),
              const Reveal(delayMs: 200, child: _SensorSection()),
              const SizedBox(height: DashboardTheme.space16),
              Reveal(
                delayMs: 240,
                child: _SyncOrChartSection(selectedDay: _selectedDay),
              ),
              const SizedBox(height: DashboardTheme.space16),
              const Reveal(delayMs: 300, child: _QuickActionsCard()),
              const SizedBox(height: DashboardTheme.space16),
              Reveal(
                delayMs: 340,
                child: _DailyInsightsCard(selectedDay: _selectedDay),
              ),
              const SizedBox(height: DashboardTheme.space16),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: DashboardTheme.surface,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                icon,
                size: 20,
                color: DashboardTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Week strip
// ---------------------------------------------------------------------------

class _WeekStripSection extends StatelessWidget {
  const _WeekStripSection({
    required this.selectedDay,
    required this.onDaySelected,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return Consumer<CGMDashboardProvider>(
      builder: (context, provider, _) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekDates = weekOf(today);

        const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

        var selectedIndex = 0;
        for (var i = 0; i < weekDates.length; i++) {
          if (weekDates[i] == selectedDay) {
            selectedIndex = i;
            break;
          }
        }

        final days = List<WeekDayScore>.generate(7, (i) {
          final date = weekDates[i];
          final isFuture = date.isAfter(today);

          if (isFuture) {
            return WeekDayScore(label: labels[i], enabled: false);
          }

          final snapshot = DaySnapshot.forDay(date, provider.readings);

          if (!snapshot.hasReadings) {
            // Day in the past with no readings — still tappable so the
            // user can see an empty state for that day.
            return WeekDayScore(label: labels[i]);
          }

          final tir = snapshot.timeInRangePercent;

          return WeekDayScore(
            label: labels[i],
            score: tir,
            severity: tir >= 80
                ? ScoreSeverity.good
                : tir >= 60
                    ? ScoreSeverity.warn
                    : ScoreSeverity.bad,
          );
        });

        return WeekScoreStrip(
          days: days,
          selectedIndex: selectedIndex,
          onDayTap: (index) {
            final date = weekDates[index];
            if (date.isAfter(today)) return;
            onDaySelected(date);
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Gauge
// ---------------------------------------------------------------------------

class _GaugeSection extends StatelessWidget {
  const _GaugeSection({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    return Consumer<CGMDashboardProvider>(
      builder: (context, provider, _) {
        final snapshot = DaySnapshot.forDay(selectedDay, provider.readings);

        // Map glucose to 0..1 over a 50-180 mg/dL range so the dial
        // visualisation stays meaningful for typical readings.
        final value = snapshot.glucose ?? 0;
        final fill = ((value - 50) / 130).clamp(0.0, 1.0);

        final t = snapshot.trend.toLowerCase();
        final trend = t.contains('fall')
            ? GaugeTrend.down
            : t.contains('ris')
                ? GaugeTrend.up
                : GaugeTrend.stable;

        return Center(
          child: GlucoseGauge(
            value: snapshot.glucose,
            fillFraction: fill,
            trend: trend,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Metabolic score card
// ---------------------------------------------------------------------------

class _ScoreSection extends StatelessWidget {
  const _ScoreSection({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    return Consumer<CGMDashboardProvider>(
      builder: (context, provider, _) {
        final snapshot = DaySnapshot.forDay(selectedDay, provider.readings);

        final tir = snapshot.timeInRangePercent;
        final ts = snapshot.lastReadingAt;
        final tsLabel = ts == null ? '--' : DateFormat('h:mm a').format(ts);

        final value = (snapshot.glucose ?? 100).clamp(40, 240);
        final position = ((value - 40) / 200).clamp(0.0, 1.0);

        return MetabolicScoreCard(
          score: tir,
          trendUp: tir >= 80,
          currentMgDl: snapshot.glucose ?? 0,
          timestamp: tsLabel,
          scalePosition: position.toDouble(),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Alert
// ---------------------------------------------------------------------------

class _AlertSection extends StatelessWidget {
  const _AlertSection({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    return Consumer<CGMDashboardProvider>(
      builder: (context, provider, _) {
        // Only show the live alert banner when looking at today.
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (selectedDay != today) return const SizedBox.shrink();

        if (!provider.showAlert) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: DashboardTheme.space16),
          child: GlucoseAlertCard(
            message: provider.alertMessage,
            color: provider.alertColor,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sensor status (kept — preserves existing UX)
// ---------------------------------------------------------------------------

class _SensorSection extends StatelessWidget {
  const _SensorSection();

  @override
  Widget build(BuildContext context) {
    return const SensorStatusCard();
  }
}

// ---------------------------------------------------------------------------
// Sync progress or chart card
// ---------------------------------------------------------------------------

class _SyncOrChartSection extends StatelessWidget {
  const _SyncOrChartSection({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    return Consumer2<CGMProvider, CGMDashboardProvider>(
      builder: (context, cgm, dashboard, _) {
        // Sync progress UI only makes sense while viewing today.
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final isToday = selectedDay == today;

        if (isToday && cgm.syncProgress < 1) {
          return SyncProgressCard(
            progress: cgm.syncProgress,
            status: cgm.connectionText,
            color: cgm.statusColor,
          );
        }

        final snapshot = DaySnapshot.forDay(selectedDay, dashboard.readings);

        if (!snapshot.hasReadings) {
          return _ChartEmptyCard(
            isLoading: dashboard.isLoadingHistory,
            day: selectedDay,
            isToday: isToday,
          );
        }

        final last = snapshot.readings.last;
        final lastTime = DateFormat('h:mm').format(last.readingAt);
        final lastValue = '${last.glucoseValue.round()} mg/dL';

        return GlucoseChartCard(
          chart: GlucoseChart(
            key: ValueKey(
              '${selectedDay.toIso8601String()}-${snapshot.readings.length}',
            ),
            spots: snapshot.glucoseSpots,
            timestamps:
                snapshot.readings.map((r) => r.readingAt).toList(growable: false),
          ),
          showSpikeTag: snapshot.spikeCount > 0,
          lastReadingLabel: lastTime,
          lastReadingValue: lastValue,
          avgGlucose: snapshot.averageGlucose,
          stdDev: snapshot.stdDev,
          spikeTime: snapshot.spikeTime,
          spikeCount: snapshot.spikeCount,
        );
      },
    );
  }
}

class _ChartEmptyCard extends StatelessWidget {
  const _ChartEmptyCard({
    required this.isLoading,
    required this.day,
    required this.isToday,
  });

  final bool isLoading;
  final DateTime day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final title = isToday
        ? 'Waiting for first reading'
        : 'No readings for ${DateFormat('MMM d').format(day)}';

    final subtitle = isToday
        ? 'Your live glucose chart will appear here.'
        : 'Try a different day from the strip above.';

    return Container(
      padding: const EdgeInsets.all(DashboardTheme.space24),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
        boxShadow: DashboardTheme.cardShadow,
      ),
      child: SizedBox(
        height: 220,
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(
                  color: DashboardTheme.accent,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 56,
                      color: DashboardTheme.track,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: DashboardTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: DashboardTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DashboardTheme.space20),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
        boxShadow: DashboardTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: DashboardTheme.heading),
          const SizedBox(height: 4),
          const Text(
            'Log anything with one tap.',
            style: DashboardTheme.body,
          ),
          const SizedBox(height: DashboardTheme.space16),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.water_drop_rounded,
                  label: 'Insulin',
                  color: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InsulinScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: DashboardTheme.space12),
              Expanded(
                child: _ActionTile(
                  icon: Icons.bloodtype_rounded,
                  label: 'Finger Stick',
                  color: DashboardTheme.danger,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FingerBloodScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: DashboardTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily insights
// ---------------------------------------------------------------------------

class _DailyInsightsCard extends StatelessWidget {
  const _DailyInsightsCard({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    return Consumer<CGMDashboardProvider>(
      builder: (context, provider, _) {
        final snapshot = DaySnapshot.forDay(selectedDay, provider.readings);

        final tir = snapshot.timeInRangePercent;
        final hasData = snapshot.hasReadings;

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final isToday = selectedDay == today;

        final headline = isToday
            ? 'Daily Insights'
            : 'Insights for ${DateFormat('MMM d').format(selectedDay)}';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DashboardTheme.space20),
          decoration: BoxDecoration(
            color: DashboardTheme.surface,
            borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
            boxShadow: DashboardTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(headline, style: DashboardTheme.heading),
              const SizedBox(height: 4),
              const Text(
                'Signals and suggestions based on the day\'s readings.',
                style: DashboardTheme.body,
              ),
              const SizedBox(height: DashboardTheme.space16),
              if (!hasData)
                const _InsightTile(
                  icon: Icons.info_outline_rounded,
                  title: 'No readings',
                  subtitle: 'There were no sensor readings on this day.',
                )
              else ...[
                _InsightTile(
                  icon: tir >= 70
                      ? Icons.check_circle_outline_rounded
                      : Icons.insights_rounded,
                  title:
                      tir >= 70 ? 'Great control' : 'Time in range: $tir%',
                  subtitle: tir >= 70
                      ? '$tir% of readings were in range.'
                      : 'Aim for 70%+ of readings between 70 and 180 mg/dL.',
                ),
                const SizedBox(height: 12),
                _InsightTile(
                  icon: snapshot.spikeCount > 0
                      ? Icons.warning_amber_rounded
                      : Icons.timeline_rounded,
                  title: snapshot.spikeCount > 0
                      ? '${snapshot.spikeCount} spike${snapshot.spikeCount == 1 ? '' : 's'} detected'
                      : 'Stable trend',
                  subtitle: snapshot.spikeCount > 0
                      ? 'Spent ${snapshot.spikeTime} above 180 mg/dL.'
                      : 'Readings stayed within the target range.',
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(DashboardTheme.radiusSm),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: DashboardTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: DashboardTheme.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Notifications sheet
// ---------------------------------------------------------------------------

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DashboardTheme.surface,
            borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
            boxShadow: DashboardTheme.cardShadow,
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: DashboardTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Alerts and sensor events will appear here.',
                style: TextStyle(
                  color: DashboardTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
