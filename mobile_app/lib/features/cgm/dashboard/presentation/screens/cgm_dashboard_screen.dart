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

class CGMDashboardScreen
    extends StatefulWidget {
  const CGMDashboardScreen({
    super.key,
  });

  @override
  State<CGMDashboardScreen>
      createState() =>
          _CGMDashboardScreenState();
}

class _CGMDashboardScreenState
    extends State<CGMDashboardScreen> {
  CGMDashboardProvider?
      _dashboardProvider;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) return;

      context
          .read<
              CGMDashboardProvider>()
          .startRealtimeUpdates();

      context
          .read<CGMProvider>()
          .fetchDevices();

      // Warm caches for the Recent Activities feed.
      context
          .read<FoodProvider>()
          .fetchFoods();
      context
          .read<
              ExerciseProvider>()
          .fetchExercises();
      context
          .read<
              InsulinProvider>()
          .fetchInsulins();
      context
          .read<
              FingerBloodProvider>()
          .fetchFingerBloods();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _dashboardProvider =
        context.read<
            CGMDashboardProvider>();
  }

  @override
  void dispose() {
    _dashboardProvider
        ?.stopUpdates();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            const Color(0xffF5F7FB),
        title: const Text(
          "CGM Dashboard",
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const DeviceManagementScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons
                  .medical_services_outlined,
            ),
            tooltip: "Devices",
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape:
                    const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .vertical(
                    top: Radius
                        .circular(
                      24,
                    ),
                  ),
                ),
                builder: (_) =>
                    const _NotificationsSheet(),
              );
            },
            icon: const Icon(
              Icons
                  .notifications_none,
            ),
            tooltip: "Notifications",
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context
                .read<
                    CGMProvider>()
                .fetchDevices(),
            context
                .read<
                    CGMDashboardProvider>()
                .refresh(),
          ]);
        },

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(20),
          child: Column(
            children: [
              Consumer<
                  CGMDashboardProvider>(
                builder: (
                  context,
                  provider,
                  _,
                ) {
                  return GlucoseCard(
                    glucose:
                        provider.glucose,
                    trend:
                        provider.trend,
                    lastReadingAt: provider
                        .lastReadingAt,
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              Consumer<
                  CGMDashboardProvider>(
                builder: (
                  context,
                  provider,
                  _,
                ) {
                  if (!provider
                      .showAlert) {
                    return const SizedBox();
                  }

                  return Column(
                    children: [
                      GlucoseAlertCard(
                        message: provider
                            .alertMessage,
                        color: provider
                            .alertColor,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  );
                },
              ),

              const SensorStatusCard(),

              const SizedBox(
                height: 20,
              ),

              Consumer<CGMProvider>(
                builder: (
                  context,
                  provider,
                  _,
                ) {
                  return SyncProgressCard(
                    progress: provider
                        .syncProgress,
                    status: provider
                        .connectionText,
                    color: provider
                        .statusColor,
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              _GlucoseTrendCard(),

              const SizedBox(
                height: 20,
              ),

              const _MetricsRow(),

              const SizedBox(
                height: 20,
              ),

              const _QuickActionsCard(),

              const SizedBox(
                height: 20,
              ),

              const _DailyInsightsCard(),

              const SizedBox(
                height: 20,
              ),

              const _RecentActivitiesCard(),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlucoseTrendCard
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.04),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Glucose Trend",
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<
                CGMDashboardProvider>(
              builder: (
                context,
                provider,
                _,
              ) {
                if (provider
                    .isLoadingHistory) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (!provider
                    .hasReadings) {
                  return const _ChartEmpty();
                }

                return GlucoseChart(
                  spots: provider
                      .glucoseSpots,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartEmpty
    extends StatelessWidget {
  const _ChartEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.show_chart,
            size: 56,
            color: Colors.grey
                .shade300,
          ),
          const SizedBox(height: 8),
          const Text(
            "Waiting for first reading",
            style: TextStyle(
              color: AppColors
                  .textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow
    extends StatelessWidget {
  const _MetricsRow();

  @override
  Widget build(BuildContext context) {
    return Consumer<
        CGMDashboardProvider>(
      builder:
          (context, provider, _) {
        return Row(
          children: [
            Expanded(
              child:
                  _buildMetricCard(
                title:
                    "Time In Range",
                value:
                    provider.hasReadings
                        ? "${provider.timeInRangePercent}%"
                        : "--",
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child:
                  _buildMetricCard(
                title:
                    "Avg Glucose",
                value:
                    provider.hasReadings
                        ? "${provider.averageGlucose}"
                        : "--",
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildMetricCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard
    extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child:
                    _ActionTile(
                  icon: Icons
                      .water_drop,
                  label: "Insulin",
                  color: Colors
                      .purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                const InsulinScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                    _ActionTile(
                  icon:
                      Icons.bloodtype,
                  label:
                      "Finger Stick",
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                const FingerBloodScreen(),
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

class _ActionTile
    extends StatelessWidget {
  final IconData icon;

  final String label;

  final Color color;

  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(20),
      child: Container(
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              color.withOpacity(0.08),
          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyInsightsCard
    extends StatelessWidget {
  const _DailyInsightsCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<
        CGMDashboardProvider>(
      builder:
          (context, provider, _) {
        final tir = provider
            .timeInRangePercent;

        final hasData =
            provider.hasReadings;

        final insights =
            <Widget>[];

        if (!hasData) {
          insights.add(
            _buildInsightTile(
              icon: Icons.info_outline,
              title:
                  "No readings yet",
              subtitle:
                  "Insights will appear once your sensor delivers data.",
            ),
          );
        } else {
          insights.add(
            _buildInsightTile(
              icon: tir >= 70
                  ? Icons
                      .check_circle_outline
                  : Icons
                      .trending_up,
              title: tir >= 70
                  ? "Great control"
                  : "Time in range: $tir%",
              subtitle: tir >= 70
                  ? "$tir% of recent readings were in range."
                  : "Aim for 70%+ of readings between 70 and 180 mg/dL.",
            ),
          );

          insights.add(
            const SizedBox(height: 16),
          );

          if (provider.showAlert) {
            insights.add(
              _buildInsightTile(
                icon: Icons
                    .warning_amber_rounded,
                title:
                    provider.alertMessage,
                subtitle:
                    "Take action based on your care plan.",
              ),
            );
          } else {
            insights.add(
              _buildInsightTile(
                icon: Icons
                    .timeline,
                title:
                    "Stable trend",
                subtitle:
                    "Recent readings have been within range.",
              ),
            );
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets
              .all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius
                    .circular(24),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              const Text(
                "Daily Insights",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight
                          .bold,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ...insights,
            ],
          ),
        );
      },
    );
  }

  static Widget _buildInsightTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary
                .withOpacity(0.08),
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentActivitiesCard
    extends StatelessWidget {
  const _RecentActivitiesCard();

  @override
  Widget build(BuildContext context) {
    final foods = context
        .watch<FoodProvider>()
        .foods;
    final exercises = context
        .watch<ExerciseProvider>()
        .exercises;
    final insulins = context
        .watch<InsulinProvider>()
        .insulins;
    final fingers = context
        .watch<
            FingerBloodProvider>()
        .fingerBloods;

    final rows =
        <_ActivityRow>[];

    for (final f in foods) {
      rows.add(
        _ActivityRow(
          icon: Icons.restaurant,
          title:
              "${f.title} logged",
          subtitle:
              "${f.calories} cal • ${f.carbs}g carbs",
          time: f.time,
        ),
      );
    }

    for (final e in exercises) {
      rows.add(
        _ActivityRow(
          icon: Icons
              .fitness_center,
          title:
              "${e.title} completed",
          subtitle:
              "${e.duration} min • ${e.caloriesBurned} cal",
          time: e.time,
        ),
      );
    }

    for (final i in insulins) {
      rows.add(
        _ActivityRow(
          icon: Icons.water_drop,
          title:
              "${i.insulinType} insulin",
          subtitle:
              "${i.dosage} units",
          time: i.time,
        ),
      );
    }

    for (final fb in fingers) {
      rows.add(
        _ActivityRow(
          icon: Icons.bloodtype,
          title:
              "${fb.glucoseValue} mg/dL",
          subtitle: fb.notes.isEmpty
              ? "Finger stick"
              : fb.notes,
          time: fb.time,
        ),
      );
    }

    final shown =
        rows.take(5).toList();

    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.04),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Activities",
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (shown.isEmpty)
            const Padding(
              padding:
                  EdgeInsets
                      .symmetric(
                vertical: 12,
              ),
              child: Text(
                "No activity yet. Log a meal, insulin or workout to see it here.",
                style: TextStyle(
                  color: AppColors
                      .textSecondary,
                ),
              ),
            )
          else
            ...List.generate(
              shown.length,
              (i) {
                final r = shown[i];
                return Padding(
                  padding:
                      EdgeInsets.only(
                    bottom: i ==
                            shown.length -
                                1
                        ? 0
                        : 16,
                  ),
                  child: r.build(
                    context,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ActivityRow {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor:
              AppColors.primary
                  .withOpacity(0.08),
          child: Icon(
            icon,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _NotificationsSheet
    extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<
        CGMDashboardProvider>(
      builder:
          (context, provider, _) {
        final items = <_NotifItem>[];

        if (provider.showAlert) {
          items.add(
            _NotifItem(
              icon: Icons
                  .warning_amber,
              title: provider
                  .alertMessage,
              subtitle:
                  "Latest reading is outside the target range.",
              color: provider
                  .alertColor,
            ),
          );
        }

        if (provider.lastReadingAt !=
            null) {
          items.add(
            _NotifItem(
              icon: Icons.timeline,
              title: "Sensor sync",
              subtitle:
                  "Last reading received ${provider.lastReadingAt!.toLocal()}.",
              color: Colors.blue,
            ),
          );
        }

        if (items.isEmpty) {
          items.add(
            const _NotifItem(
              icon: Icons
                  .notifications_none,
              title:
                  "No notifications",
              subtitle:
                  "Alerts will appear here when your sensor delivers data.",
              color:
                  AppColors.primary,
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets
                    .all(20),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  "Notifications",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                ...items.map(
                  (i) => Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 8,
                    ),
                    child: i,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotifItem
    extends StatelessWidget {
  final IconData icon;

  final String title;

  final String subtitle;

  final Color color;

  const _NotifItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}
