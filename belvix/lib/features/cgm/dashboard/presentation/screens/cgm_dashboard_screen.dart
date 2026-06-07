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
import '../widgets/glucose_metrics.dart';
import '../widgets/glucose_timeline_chart.dart';
import '../widgets/glucose_gauge.dart';
import '../widgets/metabolic_score_card.dart';
import '../widgets/sensor_warmup_nudge.dart';
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

class _CGMDashboardScreenState extends State<CGMDashboardScreen>
    with WidgetsBindingObserver {
  CGMDashboardProvider? _dashboardProvider;

  late DateTime _selectedDay;

  String _userName = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the foreground: catch up on any readings the sensor
    // buffered while we were backgrounded, so the user never has to fully
    // restart the app to see new readings/biomarkers.
    if (state == AppLifecycleState.resumed) {
      _dashboardProvider?.onAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      body: Stack(
        children: [
          RefreshIndicator(
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

          // Warm-up nudge: slides up from the bottom and stays only while
          // the sensor is preheating (live countdown from activation time).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Consumer<CGMProvider>(
              builder: (context, cgm, _) {
                final ends = cgm.warmupEndsAt;
                final show = cgm.isWarmingUp && ends != null;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                  child: show
                      ? SensorWarmupNudge(
                          key: const ValueKey('warmup'),
                          warmupEndsAt: ends,
                          onFinished: () {
                            if (mounted) setState(() {});
                          },
                        )
                      : const SizedBox.shrink(key: ValueKey('none')),
                );
              },
            ),
          ),
        ],
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
        final Widget hero;
        if (isToday && cgm.syncProgress < 1 && !snapshot.hasReadings) {
          hero = SyncProgressCard(
            progress: cgm.syncProgress,
            status: cgm.connectionText,
            color: cgm.statusColor,
          );
        } else {
          final value = snapshot.glucose ?? 0;
          final fill = ((value - 50) / 130).clamp(0.0, 1.0);
          final t = snapshot.trend.toLowerCase();
          final trend = t.contains('fall')
              ? GaugeTrend.down
              : t.contains('ris')
              ? GaugeTrend.up
              : GaugeTrend.stable;
          hero = Center(
            child: GlucoseGauge(
              value: snapshot.glucose,
              fillFraction: fill,
              trend: trend,
              timeInRange: snapshot.timeInRangePercent,
            ),
          );
        }

        // Surface a hardware fault prominently above the hero.
        if (cgm.connectionStatus == CGMConnectionStatus.malfunction) {
          return Column(
            children: [
              _SensorMalfunctionBanner(
                message: cgm.lastError ??
                    'Sensor malfunction detected. Please replace your '
                        'CGM sensor.',
              ),
              const SizedBox(height: 16),
              hero,
            ],
          );
        }

        return hero;
      },
    );
  }
}

/// Prominent red banner shown on the dashboard when the SDK reports a
/// sensor hardware fault (error 3003 "Device malfunction" / isErrorShow).
class _SensorMalfunctionBanner extends StatelessWidget {
  const _SensorMalfunctionBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DashboardTheme.dangerSoft,
      borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.error_rounded, color: DashboardTheme.danger),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sensor malfunction',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: DashboardTheme.danger,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: DashboardTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: DashboardTheme.danger,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DeviceManagementScreen(),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      'Replace sensor',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

        // Stats summarise the selected day; the chart itself is a continuous
        // timeline over ALL loaded readings (scroll/zoom across days).
        final snapshot = DaySnapshot.forDay(selectedDay, dashboard.readings);

        if (dashboard.readings.length < 2) {
          return _ChartEmptyCard(
            isLoading: dashboard.isLoadingHistory,
            day: selectedDay,
            isToday: isToday,
          );
        }

        return GlucoseChartCard(
          // No key → the State (and its scroll window) persists across
          // rebuilds and day changes; new readings update it in place.
          chart: GlucoseTimelineChart(
            readings: dashboard.readings,
            onAddAtTime: (time) => _showAddAtTime(context, time),
            onLoadOlder: dashboard.loadOlderReadings,
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
// Interpretation cards (dynamic, per selected day + 14-day GMI/CV)
// ---------------------------------------------------------------------------

class _MetricsSection extends StatelessWidget {
  const _MetricsSection({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    return Consumer2<CGMDashboardProvider, FoodProvider>(
      builder: (context, dashboard, food, _) {
        final all = dashboard.readings;
        if (all.length < 2) return const SizedBox.shrink();

        final snap = DaySnapshot.forDay(selectedDay, all);

        final dayStart = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
        );
        final dayEnd = dayStart.add(const Duration(days: 1));
        final meals = food.foods
            .where(
              (f) =>
                  !f.loggedAt.isBefore(dayStart) && f.loggedAt.isBefore(dayEnd),
            )
            .map((f) => f.loggedAt)
            .toList();

        final interp = GlucoseMetrics.build(
          now: DateTime.now(),
          selectedDay: selectedDay,
          dayReadings: snap.readings,
          allReadings: all,
          dayMeals: meals,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Interpretation', style: _h2),
            const SizedBox(height: 12),
            if (interp.severeHypo) ...[
              const _SevereHypoBanner(),
              const SizedBox(height: 14),
            ],
            for (var i = 0; i < interp.metrics.length; i++) ...[
              _MetricCard(
                metric: interp.metrics[i],
                onTap: interp.metrics[i].tappable
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GmiScreen()),
                      )
                    : null,
              ),
              if (i < interp.metrics.length - 1) const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }
}

class _SevereHypoBanner extends StatelessWidget {
  const _SevereHypoBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DashboardTheme.dangerSoft,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: const [
            Icon(Icons.error_outline_rounded, color: DashboardTheme.danger),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Severe low detected',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: DashboardTheme.danger,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'A reading fell below 54 mg/dL. Treat hypoglycemia '
                    'promptly and review your insulin/medication.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: DashboardTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, this.onTap});

  final Metric metric;
  final VoidCallback? onTap;

  Color get _statusColor {
    switch (metric.status) {
      case MetricStatus.optimal:
        return DashboardTheme.accent;
      case MetricStatus.moderate:
        return DashboardTheme.warn;
      case MetricStatus.outOfRange:
        return DashboardTheme.danger;
      case MetricStatus.collecting:
        return DashboardTheme.textMuted;
    }
  }

  String get _statusLabel {
    switch (metric.status) {
      case MetricStatus.optimal:
        return 'OPTIMAL';
      case MetricStatus.moderate:
        return 'MODERATE';
      case MetricStatus.outOfRange:
        return 'OUT OF RANGE';
      case MetricStatus.collecting:
        return 'COLLECTING DATA';
    }
  }

  @override
  Widget build(BuildContext context) {
    final collecting = metric.status == MetricStatus.collecting;
    final color = _statusColor;
    // Higher-is-better metrics (TIR) put "Optimal" on the right.
    final leftLabel = metric.higherIsBetter ? 'Out of range' : 'Optimal';
    final rightLabel = metric.higherIsBetter ? 'Optimal' : 'Out of range';

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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              metric.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: DashboardTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (metric.severe) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: DashboardTheme.danger,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color,
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
                      metric.value,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: DashboardTheme.textPrimary,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                    if (!collecting) ...[
                      const SizedBox(width: 4),
                      Text(
                        metric.unit,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: DashboardTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _StatusMeter(
              position: metric.position,
              higherIsBetter: metric.higherIsBetter,
              statusColor: color,
              disabled: collecting,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leftLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DashboardTheme.textMuted,
                  ),
                ),
                Text(
                  rightLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DashboardTheme.textMuted,
                  ),
                ),
              ],
            ),
            if (metric.detail != null) ...[
              const SizedBox(height: 12),
              Text(
                metric.detail!,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: DashboardTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              metric.recommendation,
              style: const TextStyle(
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

/// Three-zone status meter (green/amber/red) with a marker. For
/// higher-is-better metrics the green zone is on the right. Painted on a
/// canvas so it renders reliably.
class _StatusMeter extends StatelessWidget {
  const _StatusMeter({
    required this.position,
    required this.higherIsBetter,
    required this.statusColor,
    this.disabled = false,
  });

  final double position;
  final bool higherIsBetter;
  final Color statusColor;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: CustomPaint(
        size: Size.infinite,
        painter: _MeterPainter(
          position: position.clamp(0.0, 1.0).toDouble(),
          higherIsBetter: higherIsBetter,
          marker: statusColor,
          disabled: disabled,
        ),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  _MeterPainter({
    required this.position,
    required this.higherIsBetter,
    required this.marker,
    required this.disabled,
  });

  final double position;
  final bool higherIsBetter;
  final Color marker;
  final bool disabled;

  @override
  void paint(Canvas canvas, Size size) {
    const h = 6.0, gap = 4.0;
    final y = size.height / 2;
    final segW = (size.width - 2 * gap) / 3;

    final colors = disabled
        ? const [
            DashboardTheme.track,
            DashboardTheme.track,
            DashboardTheme.track,
          ]
        : higherIsBetter
        ? const [
            DashboardTheme.danger,
            DashboardTheme.warn,
            DashboardTheme.accent,
          ]
        : const [
            DashboardTheme.accent,
            DashboardTheme.warn,
            DashboardTheme.danger,
          ];

    for (var i = 0; i < 3; i++) {
      final left = i * (segW + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, y - h / 2, segW, h),
          const Radius.circular(3),
        ),
        Paint()..color = colors[i].withValues(alpha: disabled ? 1 : 0.9),
      );
    }

    if (!disabled) {
      final cx = (position * size.width).clamp(8.0, size.width - 8);
      canvas.drawCircle(Offset(cx, y), 8, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(cx, y), 6, Paint()..color = marker);
    }
  }

  @override
  bool shouldRepaint(covariant _MeterPainter old) =>
      old.position != position ||
      old.disabled != disabled ||
      old.higherIsBetter != higherIsBetter ||
      old.marker != marker;
}

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

enum _TimelineFilter { all, food, exercise, insulin, finger }

class _TimelineEntry {
  const _TimelineEntry({
    required this.kind,
    required this.icon,
    required this.iconColor,
    required this.time,
    required this.title,
    this.subtitle,
  });

  /// Used by the filter tabs. Glucose alerts use [_TimelineFilter.all] so
  /// they only show under "All".
  final _TimelineFilter kind;
  final IconData icon;
  final Color iconColor;
  final String time;
  final String title;
  final String? subtitle;
}

class _TimelineSection extends StatefulWidget {
  const _TimelineSection();

  @override
  State<_TimelineSection> createState() => _TimelineSectionState();
}

class _TimelineSectionState extends State<_TimelineSection> {
  _TimelineFilter _filter = _TimelineFilter.all;

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
                kind: _TimelineFilter.all,
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
              kind: _TimelineFilter.food,
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
              kind: _TimelineFilter.exercise,
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
              kind: _TimelineFilter.insulin,
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
              kind: _TimelineFilter.finger,
              icon: Icons.bloodtype_outlined,
              iconColor: DashboardTheme.danger,
              time: f.time,
              title: 'Glucose Meter · ${f.glucoseValue} mg/dL',
              subtitle: f.notes.isEmpty ? null : f.notes,
            ),
          );
        }

        final visible = _filter == _TimelineFilter.all
            ? entries
            : entries.where((e) => e.kind == _filter).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Timeline', style: _h2),
            const SizedBox(height: 12),
            _TimelineTabs(
              selected: _filter,
              onSelected: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 14),
            if (visible.isEmpty)
              _EmptyHint(
                _filter == _TimelineFilter.all
                    ? 'No events logged for today yet.'
                    : 'No ${_filterLabel(_filter).toLowerCase()} logged yet.',
              )
            else
              for (final e in visible)
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

String _filterLabel(_TimelineFilter f) {
  switch (f) {
    case _TimelineFilter.all:
      return 'All';
    case _TimelineFilter.food:
      return 'Food';
    case _TimelineFilter.exercise:
      return 'Exercise';
    case _TimelineFilter.insulin:
      return 'Insulin';
    case _TimelineFilter.finger:
      return 'Glucose Meter';
  }
}

/// Horizontally scrollable pill tabs for filtering the timeline.
/// Short label used on the compact segmented tabs.
String _filterTab(_TimelineFilter f) =>
    f == _TimelineFilter.finger ? 'Meter' : _filterLabel(f);

/// Segmented control: a grey track with the selected option as a green
/// pill and thin dividers between the unselected ones.
class _TimelineTabs extends StatelessWidget {
  const _TimelineTabs({required this.selected, required this.onSelected});

  final _TimelineFilter selected;
  final ValueChanged<_TimelineFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = _TimelineFilter.values;

    // Material paints the fills (a plain BoxDecoration renders transparent
    // on some devices).
    return Material(
      color: const Color(0xFFEDEEF1),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (var i = 0; i < filters.length; i++) ...[
              Expanded(
                child: _Segment(
                  label: _filterTab(filters[i]),
                  selected: filters[i] == selected,
                  onTap: () => onSelected(filters[i]),
                ),
              ),
              if (i < filters.length - 1)
                SizedBox(
                  width: 1,
                  height: 16,
                  child: ColoredBox(
                    color:
                        (filters[i] != selected &&
                            filters[i + 1] != selected)
                        ? const Color(0xFFCDD2D9)
                        : Colors.transparent,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DashboardTheme.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : DashboardTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
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
