import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../core/storage/storage_service.dart';
import '../../../../../core/widgets/app_surface.dart';
import '../../../../dashboard/presentation/widgets/app_bottom_nav_bar.dart';
import '../../../../exercise/presentation/providers/exercise_provider.dart';
import '../../../../exercise/presentation/widgets/add_exercise_bottomsheet.dart';
import '../../../../finger_blood/presentation/providers/finger_blood_provider.dart';
import '../../../../finger_blood/presentation/screens/finger_blood_screen.dart';
import '../../../../food/presentation/providers/food_provider.dart';
import '../../../../food/presentation/widgets/add_food_bottomsheet.dart';
import '../../../../insulin/presentation/providers/insulin_provider.dart';
import '../../../../insulin/presentation/screens/insulin_screen.dart';
import '../../../connect/presentation/providers/cgm_provider.dart';
import '../../../connect/presentation/screens/device_management_screen.dart';
import '../providers/cgm_dashboard_provider.dart';
import '../widgets/dashboard_theme.dart';
import '../widgets/day_snapshot.dart';
import '../widgets/glucose_chart_card.dart';
import '../widgets/glucose_trend_chart.dart';
import '../widgets/glucose_gauge.dart';
import '../widgets/metabolic_score_card.dart';
import '../widgets/sync_progress_card.dart';
import '../widgets/week_score_strip.dart';
import 'gmi_screen.dart';

/// Production CGM dashboard — the "Hub · Data" experience.
///
/// All metrics recompute from a [DaySnapshot] of the readings for the
/// selected day (driven by the week strip). Food / exercise / insulin /
/// finger-blood providers feed the Timeline and Total Macros sections.
class CGMDashboardScreen extends StatefulWidget {
  const CGMDashboardScreen({super.key});

  @override
  State<CGMDashboardScreen> createState() => _CGMDashboardScreenState();
}

class _CGMDashboardScreenState extends State<CGMDashboardScreen> {
  CGMDashboardProvider? _dashboardProvider;

  late DateTime _selectedDay;

  String _userName = '';

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);

    StorageService.getUser().then((u) {
      if (!mounted) return;
      final name = (u?['fullName'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        setState(() => _userName = name);
      }
    });

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
    setState(() => _selectedDay = day);
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
        title: Text(
          _userName.isEmpty ? 'HI' : 'HI, ${_userName.toUpperCase()}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: DashboardTheme.textPrimary,
          ),
        ),
        actions: [
          _AppBarIconButton(
            tooltip: 'Devices',
            icon: Icons.medical_services_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeviceManagementScreen()),
            ),
          ),
          Consumer<CGMDashboardProvider>(
            builder: (context, provider, _) {
              final count = provider.glucoseEvents.length;
              return _AppBarIconButton(
                tooltip: 'Notifications',
                icon: Icons.notifications_none_rounded,
                badgeCount: count,
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: const _NotificationsSheet(),
                    ),
                  );
                },
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
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          // Extra bottom padding so the last card clears the floating
          // bottom navigation bar at the end of the scroll.
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          children: [
            _WeekStripSection(
              selectedDay: _selectedDay,
              onDaySelected: _onDaySelected,
            ),
            const SizedBox(height: 16),
            _GaugeSection(selectedDay: _selectedDay),
            const SizedBox(height: 16),
            _ScoreSection(selectedDay: _selectedDay),
            const SizedBox(height: 16),
            _ChartSection(selectedDay: _selectedDay),
            const SizedBox(height: 16),
            _MetricsSection(selectedDay: _selectedDay),
            const SizedBox(height: 24),
            const _TimelineSection(),
            const SizedBox(height: 20),
            const _TotalMacrosSection(),
          ],
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

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Consumer<CGMDashboardProvider>(
      builder: (context, provider, _) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

        // The last year, oldest -> newest (matches the data window).
        final dates = List<DateTime>.generate(
          365,
          (i) => DateTime(today.year, today.month, today.day - (364 - i)),
        );

        var selectedIndex = dates.length - 1;
        final days = <WeekDayScore>[];
        for (var i = 0; i < dates.length; i++) {
          final date = dates[i];
          if (_isSameDay(date, selectedDay)) selectedIndex = i;

          final snapshot = DaySnapshot.forDay(date, provider.readings);
          if (!snapshot.hasReadings) {
            days.add(WeekDayScore(date: date, label: labels[date.weekday - 1]));
            continue;
          }

          // Show the day's average glucose with range-based severity.
          final avg = snapshot.averageGlucose;
          days.add(
            WeekDayScore(
              date: date,
              label: labels[date.weekday - 1],
              score: avg,
              severity: avg >= 70 && avg <= 140
                  ? ScoreSeverity.good
                  : avg <= 180
                  ? ScoreSeverity.warn
                  : ScoreSeverity.bad,
            ),
          );
        }

        return WeekScoreStrip(
          days: days,
          selectedIndex: selectedIndex,
          onDayTap: (index) => onDaySelected(days[index].date),
          onPickDate: () async {
            final initial = selectedDay.isBefore(dates.first)
                ? dates.first
                : (selectedDay.isAfter(dates.last) ? dates.last : selectedDay);
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: dates.first,
              lastDate: dates.last,
              builder: (context, child) {
                final base = Theme.of(context);
                return Theme(
                  data: base.copyWith(
                    colorScheme: base.colorScheme.copyWith(
                      primary: DashboardTheme.textPrimary,
                      onPrimary: Colors.white,
                      onSurface: DashboardTheme.textPrimary,
                    ),
                    datePickerTheme: DatePickerThemeData(
                      backgroundColor: Colors.white,
                      headerBackgroundColor: DashboardTheme.textPrimary,
                      headerForegroundColor: Colors.white,
                      dayForegroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected)
                            ? Colors.white
                            : DashboardTheme.textPrimary,
                      ),
                      dayBackgroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected)
                            ? DashboardTheme.textPrimary
                            : null,
                      ),
                      todayForegroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected)
                            ? Colors.white
                            : DashboardTheme.textPrimary,
                      ),
                      todayBackgroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected)
                            ? DashboardTheme.textPrimary
                            : null,
                      ),
                      todayBorder: const BorderSide(
                        color: DashboardTheme.textPrimary,
                      ),
                      yearForegroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected)
                            ? Colors.white
                            : DashboardTheme.textPrimary,
                      ),
                      yearBackgroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected)
                            ? DashboardTheme.textPrimary
                            : null,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onDaySelected(DateTime(picked.year, picked.month, picked.day));
            }
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Gauge (or sync card while syncing today)
// ---------------------------------------------------------------------------

class _GaugeSection extends StatelessWidget {
  const _GaugeSection({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    return Consumer2<CGMProvider, CGMDashboardProvider>(
      builder: (context, cgm, provider, _) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final isToday = selectedDay == today;

        final snapshot = DaySnapshot.forDay(selectedDay, provider.readings);

        // Only show the sync card during the *initial* sync, before any
        // reading exists. Once readings arrive, the gauge takes over and
        // updates live with every new reading.
        if (isToday && cgm.syncProgress < 1 && !snapshot.hasReadings) {
          return SyncProgressCard(
            progress: cgm.syncProgress,
            status: cgm.connectionText,
            color: cgm.statusColor,
          );
        }

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
            timeInRange: snapshot.timeInRangePercent,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Metabolic score
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
// Chart
// ---------------------------------------------------------------------------

class _ChartSection extends StatelessWidget {
  const _ChartSection({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    return Consumer<CGMDashboardProvider>(
      builder: (context, dashboard, _) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final isToday = selectedDay == today;

        final snapshot = DaySnapshot.forDay(selectedDay, dashboard.readings);

        if (!snapshot.hasReadings) {
          return _ChartEmptyCard(
            isLoading: dashboard.isLoadingHistory,
            day: selectedDay,
            isToday: isToday,
          );
        }

        return GlucoseChartCard(
          chart: GlucoseTrendChart(
            // Stable per-day key: a new reading updates the existing chart
            // in place (preserving zoom/scroll/tooltip) instead of rebuilding.
            key: ValueKey(selectedDay),
            readings: snapshot.readings,
            onAddAtTime: (time) => _showAddAtTime(context, time),
          ),
          showSpikeTag: snapshot.spikeCount > 0,
          avgGlucose: snapshot.averageGlucose,
          stdDev: snapshot.stdDev,
          spikeTime: snapshot.spikeTime,
          spikeCount: snapshot.spikeCount,
        );
      },
    );
  }
}

/// Tapping "+" on a chart point opens the quick-action menu; choosing an
/// action opens that logger pre-set to log at the tapped reading's time.
void _showAddAtTime(BuildContext context, DateTime time) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: QuickActionMenu(
          onActionTap: (type) {
            Navigator.pop(sheetContext);
            _openLoggerFor(context, type, time);
          },
        ),
      ),
    ),
  );
}

void _openLoggerFor(BuildContext context, QuickActionType type, DateTime time) {
  const sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
  );

  switch (type) {
    case QuickActionType.diet:
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: sheetShape,
        builder: (_) => AddFoodBottomSheet(initialTime: time),
      );
      break;
    case QuickActionType.exercise:
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: sheetShape,
        builder: (_) => AddExerciseBottomSheet(initialTime: time),
      );
      break;
    case QuickActionType.insulin:
      showDialog<void>(
        context: context,
        builder: (_) => AddInsulinDialog(initialTime: time),
      );
      break;
    case QuickActionType.fingerBlood:
      showDialog<void>(
        context: context,
        builder: (_) => AddFingerBloodDialog(initialTime: time),
      );
      break;
    case QuickActionType.medicine:
      break;
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

    return AppSurface(
      padding: const EdgeInsets.all(DashboardTheme.space24),
      radius: DashboardTheme.radiusLg,
      child: SizedBox(
        height: 200,
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: DashboardTheme.accent)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.show_chart_rounded,
                      size: 48,
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
                  ],
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metric cards (Time above range / Time in range / Excursion / GMI / Osc.)
// ---------------------------------------------------------------------------

class _MetricsSection extends StatelessWidget {
  const _MetricsSection({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    return Consumer<CGMDashboardProvider>(
      builder: (context, provider, _) {
        final s = DaySnapshot.forDay(selectedDay, provider.readings);

        if (!s.hasReadings) return const SizedBox.shrink();

        final total = s.readings.length;
        final aboveMin =
            s.readings.where((r) => r.glucoseValue > 180).length * 5;
        final inRangeMin =
            s.readings
                .where((r) => r.glucoseValue >= 70 && r.glucoseValue <= 180)
                .length *
            5;

        final values = s.readings.map((r) => r.glucoseValue).toList();
        final excursion = values.isEmpty
            ? 0
            : (values.reduce((a, b) => a > b ? a : b) -
                      values.reduce((a, b) => a < b ? a : b))
                  .round();

        final gmi = 3.31 + 0.02392 * s.averageGlucose;

        return Column(
          children: [
            _MetricCard(
              title: 'Time above range',
              value: '$aboveMin',
              unit: 'min',
              badness: (aboveMin / 180).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 14),
            _MetricCard(
              title: 'Time in range',
              value: '$inRangeMin',
              unit: 'min',
              badness: (1 - (total == 0 ? 0.0 : inRangeMin / (total * 5)))
                  .clamp(0.0, 1.0),
            ),
            const SizedBox(height: 14),
            _MetricCard(
              title: 'Time out of range',
              value: '${s.timeOutOfRangePercent}',
              unit: '%',
              badness: (s.timeOutOfRangePercent / 50).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 14),
            _MetricCard(
              title: 'Hyperglycemic events',
              value: '${s.hyperEvents}',
              unit: 'events',
              badness: (s.hyperEvents / 5).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 14),
            _MetricCard(
              title: 'Hypoglycemic events',
              value: '${s.hypoEvents}',
              unit: 'events',
              badness: (s.hypoEvents / 3).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 14),
            _MetricCard(
              title: 'Glucose Excursion',
              value: '$excursion',
              unit: 'mg/dL',
              badness: ((excursion - 40) / 120).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 14),
            _MetricCard(
              title: 'GMI',
              value: gmi.toStringAsFixed(1),
              unit: '%',
              badness: ((gmi - 5.0) / 2.0).clamp(0.0, 1.0),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GmiScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _MetricCard(
              title: 'Glucose Oscillation',
              value: '${s.stdDev}',
              unit: 'mg/dL',
              badness: ((s.stdDev - 10) / 40).clamp(0.0, 1.0),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.badness,
    this.onTap,
  });

  final String title;
  final String value;
  final String unit;
  final double badness; // 0 = optimal, 1 = elevated
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = badness < 0.34
        ? 'OPTIMAL'
        : badness < 0.67
        ? 'MODERATE'
        : 'ELEVATED';
    final statusColor = badness < 0.34
        ? DashboardTheme.accent
        : badness < 0.67
        ? DashboardTheme.warn
        : DashboardTheme.danger;

    return GestureDetector(
      onTap: onTap,
      child: AppSurface(
        padding: const EdgeInsets.all(18),
        radius: DashboardTheme.radiusLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: DashboardTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: DashboardTheme.textPrimary,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DashboardTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SegmentedMeter(position: badness, dotColor: statusColor),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Optimal',
                  style: TextStyle(
                    fontSize: 12,
                    color: DashboardTheme.textMuted,
                  ),
                ),
                Text(
                  'Elevated',
                  style: TextStyle(
                    fontSize: 12,
                    color: DashboardTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Your glucose levels have been stable today. Focus on balanced '
              'meals and activity to help your body to balance glucose.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: DashboardTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedMeter extends StatelessWidget {
  const _SegmentedMeter({required this.position, required this.dotColor});

  final double position; // 0..1
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return SizedBox(
          height: 14,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Row(
                children: List.generate(4, (i) {
                  final segCenter = (i + 0.5) / 4;
                  final filled = segCenter <= position + 0.02;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                      height: 5,
                      decoration: BoxDecoration(
                        color: filled
                            ? DashboardTheme.textPrimary
                            : DashboardTheme.track,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
              Positioned(
                left: (position.clamp(0.0, 1.0) * w) - 7,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

class _TimelineEntry {
  const _TimelineEntry({
    required this.icon,
    required this.iconColor,
    required this.time,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String time;
  final String title;
  final String? subtitle;
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection();

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      FoodProvider,
      ExerciseProvider,
      InsulinProvider,
      FingerBloodProvider
    >(
      builder: (context, food, exercise, insulin, finger, _) {
        final dash = context.watch<CGMDashboardProvider>();
        final entries = <_TimelineEntry>[];

        // Glucose events derived from today's readings crossing 110 mg/dL.
        final today = DateTime.now();
        final snap = DaySnapshot.forDay(
          DateTime(today.year, today.month, today.day),
          dash.readings,
        );
        for (final r in snap.readings.reversed) {
          if (entries.length >= 3) break;
          if (r.glucoseValue > 110) {
            entries.add(
              _TimelineEntry(
                icon: Icons.error_outline,
                iconColor: DashboardTheme.danger,
                time: DateFormat('h:mm a').format(r.readingAt),
                title: 'Hyperglycemic event detected',
                subtitle:
                    'Your glucose (${r.glucoseValue.round()}) rose above the '
                    'max target of (110 mg/dL).',
              ),
            );
          }
        }

        // Meals — one entry per logged food item.
        for (final f in food.foods) {
          entries.add(
            _TimelineEntry(
              icon: Icons.restaurant,
              iconColor: DashboardTheme.textPrimary,
              time: f.time,
              title: f.title,
              subtitle: '${f.calories} cal · ${f.carbs}g carbs',
            ),
          );
        }

        // Exercise / activity.
        for (final e in exercise.exercises) {
          entries.add(
            _TimelineEntry(
              icon: Icons.monitor_heart_outlined,
              iconColor: DashboardTheme.textPrimary,
              time: e.time,
              title: e.title,
              subtitle: '${e.duration} min · ${e.caloriesBurned} kcal',
            ),
          );
        }

        // Insulin doses.
        for (final i in insulin.insulins) {
          entries.add(
            _TimelineEntry(
              icon: Icons.water_drop_outlined,
              iconColor: const Color(0xFF7C3AED),
              time: i.time,
              title: i.insulinType,
              subtitle: '${i.dosage} units',
            ),
          );
        }

        // Finger-stick readings.
        for (final f in finger.fingerBloods) {
          entries.add(
            _TimelineEntry(
              icon: Icons.bloodtype_outlined,
              iconColor: DashboardTheme.danger,
              time: f.time,
              title: 'Finger stick · ${f.glucoseValue} mg/dL',
              subtitle: f.notes.isEmpty ? null : f.notes,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Timeline', style: _h2),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              const _EmptyHint('No events logged for today yet.')
            else
              for (final e in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TimelineCard(entry: e),
                ),
          ],
        );
      },
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.entry});

  final _TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      radius: DashboardTheme.radiusMd,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
            child: Row(
              children: [
                Icon(entry.icon, size: 18, color: entry.iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        entry.time,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: DashboardTheme.textPrimary,
                        ),
                      ),
                      if (entry.title.isNotEmpty) ...[
                        const Text(
                          '  ·  ',
                          style: TextStyle(color: DashboardTheme.textMuted),
                        ),
                        Expanded(
                          child: Text(
                            entry.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: DashboardTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: DashboardTheme.textMuted,
                ),
              ],
            ),
          ),
          if (entry.subtitle != null) ...[
            const Divider(height: 1, color: Color(0xFFF0F2F5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Text(
                entry.subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: DashboardTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Total Macros
// ---------------------------------------------------------------------------

class _TotalMacrosSection extends StatelessWidget {
  const _TotalMacrosSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodProvider>(
      builder: (context, food, _) {
        final calories = food.foods.fold<int>(0, (sum, f) => sum + f.calories);
        final carbs = food.foods.fold<int>(0, (sum, f) => sum + f.carbs);
        final protein = food.foods.fold<int>(0, (sum, f) => sum + f.protein);
        final fat = food.foods.fold<int>(0, (sum, f) => sum + f.fat);
        final fiber = food.foods.fold<int>(0, (sum, f) => sum + f.fiber);
        final meals = food.foods.length;

        return AppSurface(
          padding: const EdgeInsets.all(18),
          radius: DashboardTheme.radiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE5484D),
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Total Macros', style: _h2),
                  const Text(
                    '  ·  ',
                    style: TextStyle(color: DashboardTheme.textMuted),
                  ),
                  Text(
                    '$meals meals',
                    style: const TextStyle(
                      fontSize: 15,
                      color: DashboardTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF0F2F5)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MacroRing(
                    value: '$calories',
                    label: 'Calories',
                    color: DashboardTheme.textPrimary,
                    fraction: 1,
                  ),
                  _MacroRing(
                    value: '${protein}g',
                    label: 'Protein',
                    color: const Color(0xFFE5484D),
                    fraction: (protein / 200).clamp(0.0, 1.0),
                  ),
                  _MacroRing(
                    value: '${fat}g',
                    label: 'Fat',
                    color: const Color(0xFF3B82F6),
                    fraction: (fat / 200).clamp(0.0, 1.0),
                  ),
                  _MacroRing(
                    value: '${carbs}g',
                    label: 'Carbs',
                    color: const Color(0xFFE89240),
                    fraction: (carbs / 300).clamp(0.0, 1.0),
                  ),
                  _MacroRing(
                    value: '${fiber}g',
                    label: 'Fiber',
                    color: const Color(0xFF16A34A),
                    fraction: (fiber / 60).clamp(0.0, 1.0),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MacroRing extends StatelessWidget {
  const _MacroRing({
    required this.value,
    required this.label,
    required this.color,
    required this.fraction,
  });

  final String value;
  final String label;
  final Color color;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  value: fraction <= 0 ? 0 : fraction,
                  strokeWidth: 4,
                  backgroundColor: DashboardTheme.track,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: DashboardTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared
// ---------------------------------------------------------------------------

const _h2 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w800,
  color: DashboardTheme.textPrimary,
);

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(20),
      radius: DashboardTheme.radiusMd,
      child: Text(
        text,
        style: const TextStyle(
          color: DashboardTheme.textSecondary,
          fontWeight: FontWeight.w500,
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
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final int badgeCount;

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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    icon,
                    size: 20,
                    color: DashboardTheme.textPrimary,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: DashboardTheme.danger,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: DashboardTheme.screenBg,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifications sheet
// ---------------------------------------------------------------------------

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  String _formatTime(DateTime at) {
    final local = at.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday =
        !local.isBefore(today) &&
        local.isBefore(today.add(const Duration(days: 1)));
    return isToday
        ? DateFormat('h:mm a').format(local)
        : DateFormat('MMM d, h:mm a').format(local);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CGMDashboardProvider>(
      builder: (context, provider, _) {
        final events = provider.glucoseEvents;

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: AppSurface(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              radius: DashboardTheme.radiusLg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Notifications', style: _h2),
                      const SizedBox(width: 8),
                      if (events.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DashboardTheme.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${events.length}',
                            style: const TextStyle(
                              color: DashboardTheme.danger,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Glucose alerts and sensor events.',
                    style: TextStyle(color: DashboardTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (events.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 40,
                              color: DashboardTheme.track,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No glucose alerts',
                              style: TextStyle(
                                color: DashboardTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "You're in range — nothing to report.",
                              style: TextStyle(
                                color: DashboardTheme.textMuted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: events.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF0F2F5)),
                        itemBuilder: (context, i) {
                          final e = events[i];
                          return _NotificationRow(
                            event: e,
                            time: _formatTime(e.at),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.event, required this.time});

  final GlucoseEvent event;
  final String time;

  @override
  Widget build(BuildContext context) {
    final color = event.isLow ? DashboardTheme.danger : DashboardTheme.warn;
    final title = event.isLow ? 'Low glucose' : 'High glucose';
    final icon = event.isLow
        ? Icons.south_east_rounded
        : Icons.north_east_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
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
                    fontSize: 14,
                    color: DashboardTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${event.value} mg/dL',
                  style: const TextStyle(
                    fontSize: 13,
                    color: DashboardTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: DashboardTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
