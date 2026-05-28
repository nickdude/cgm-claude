import 'package:flutter/material.dart';
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
import '../widgets/glucose_alert_card.dart';
import '../widgets/glucose_card.dart';
import '../widgets/glucose_chart.dart';
import '../widgets/sensor_status_card.dart';
import '../widgets/sync_progress_card.dart';

class CGMDashboardScreen extends StatefulWidget {
  const CGMDashboardScreen({super.key});

  @override
  State<CGMDashboardScreen> createState() => _CGMDashboardScreenState();
}

class _CGMDashboardScreenState extends State<CGMDashboardScreen> {
  CGMDashboardProvider? _dashboardProvider;

  @override
  void initState() {
    super.initState();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F7FB),
        title: const Text('CGM Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Devices',
            icon: const Icon(Icons.medical_services_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeviceManagementScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<CGMProvider>().fetchDevices(),
            context.read<CGMDashboardProvider>().refresh(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _Reveal(
                delayMs: 0,
                child: Consumer<CGMDashboardProvider>(
                  builder: (context, provider, _) {
                    return GlucoseCard(
                      glucose: provider.glucose,
                      trend: provider.trend,
                      lastReadingAt: provider.lastReadingAt,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0B1220),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Overview of your glucose',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _Reveal(
                delayMs: 80,
                child: Consumer<CGMDashboardProvider>(
                  builder: (context, provider, _) {
                    if (!provider.showAlert) return const SizedBox.shrink();

                    return GlucoseAlertCard(
                      message: provider.alertMessage,
                      color: provider.alertColor,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const _Reveal(delayMs: 120, child: SensorStatusCard()),
              const SizedBox(height: 20),
              _Reveal(
                delayMs: 160,
                child: Consumer<CGMProvider>(
                  builder: (context, provider, _) {
                    return _SyncOrTrendCard(
                      progress: provider.syncProgress,
                      status: provider.connectionText,
                      color: provider.statusColor,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const _Reveal(delayMs: 200, child: _MetricsRow()),
              const SizedBox(height: 20),
              const _Reveal(delayMs: 240, child: _QuickActionsCard()),
              const SizedBox(height: 20),
              const _Reveal(delayMs: 280, child: _DailyInsightsCard()),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncOrTrendCard extends StatelessWidget {
  const _SyncOrTrendCard({
    required this.progress,
    required this.status,
    required this.color,
  });

  final double progress;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (progress < 1) {
      return SyncProgressCard(
        progress: progress,
        status: status,
        color: color,
      );
    }

    return const _GlucoseTrendCard();
  }
}

class _GlucoseTrendCard extends StatelessWidget {
  const _GlucoseTrendCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Consumer2<CGMProvider, CGMDashboardProvider>(
        builder: (context, cgmProvider, dashboardProvider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cgmProvider.statusColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.timeline_rounded,
                      color: cgmProvider.statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Glucose timeline',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Top axis shows date and bottom axis shows time.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${dashboardProvider.readings.length} readings',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF8FAFC), Color(0xFFF2F6FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE7EEF7)),
                ),
                child: SizedBox(
                  height: 332,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: dashboardProvider.isLoadingHistory
                        ? const Center(child: CircularProgressIndicator())
                        : dashboardProvider.hasReadings
                            ? GlucoseChart(
                                key: ValueKey(dashboardProvider.readings.length),
                                spots: dashboardProvider.glucoseSpots,
                                timestamps: dashboardProvider.readings
                                    .map((reading) => reading.readingAt)
                                    .toList(growable: false),
                              )
                            : const _ChartEmpty(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          const Text(
            'Waiting for first reading',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow();

  @override
  Widget build(BuildContext context) {
    return Consumer<CGMDashboardProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Time In Range',
                value: provider.hasReadings
                    ? '${provider.timeInRangePercent}%'
                    : '--',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                label: 'Avg Glucose',
                value: provider.hasReadings
                    ? '${provider.averageGlucose}'
                    : '--',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EEF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(
                  Icons.show_chart,
                  size: 18,
                  color: Color(0xFF9AA8B6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EEF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Log anything with one tap.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.water_drop,
                  label: 'Insulin',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InsulinScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  icon: Icons.bloodtype,
                  label: 'Finger Stick',
                  color: Colors.red,
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(color: const Color(0xFF111827), fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyInsightsCard extends StatelessWidget {
  const _DailyInsightsCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<CGMDashboardProvider>(
      builder: (context, provider, _) {
        final tir = provider.timeInRangePercent;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE7EEF7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Signals and suggestions based on recent readings.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              _InsightTile(
                icon: provider.hasReadings ? Icons.insights : Icons.info_outline,
                title: provider.hasReadings
                    ? (tir >= 70 ? 'Great control' : 'Time in range: $tir%')
                    : 'No readings yet',
                subtitle: provider.hasReadings
                    ? (tir >= 70
                        ? '$tir% of recent readings were in range.'
                        : 'Aim for 70%+ of readings between 70 and 180 mg/dL.')
                    : 'Insights will appear once your sensor delivers data.',
              ),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(18),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Alerts and sensor events will appear here.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.child, required this.delayMs});

  final Widget child;
  final int delayMs;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}