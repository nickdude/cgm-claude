import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/cgm_dashboard_provider.dart';

import '../widgets/glucose_alert_card.dart';

import '../widgets/glucose_card.dart';

import '../widgets/glucose_chart.dart';

import '../widgets/sensor_status_card.dart';

import '../widgets/sync_progress_card.dart';

import '../../../connect/presentation/providers/cgm_provider.dart';

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
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context
          .read<
              CGMDashboardProvider>()
          .startRealtimeUpdates();

      context
          .read<CGMProvider>()
          .fetchDevices();
    });
  }

  @override
  void dispose() {
    context
        .read<CGMDashboardProvider>()
        .stopUpdates();

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

        title:
            const Text("CGM Dashboard"),

        actions: [
          IconButton(
            onPressed: () {},

            icon: const Icon(
              Icons.notifications_none,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [
            Consumer<
                CGMDashboardProvider>(
              builder:
                  (
                    context,
                    provider,
                    _,
                  ) {
                return GlucoseCard(
                  glucose:
                      provider.glucose,

                  trend:
                      provider.trend,
                );
              },
            ),

            const SizedBox(height: 20),

            Consumer<
                CGMDashboardProvider>(
              builder: (
                context,
                provider,
                _,
              ) {
                if (!provider.showAlert) {
                  return const SizedBox();
                }

                return GlucoseAlertCard(
                  message:
                      provider.alertMessage,

                  color:
                      provider.alertColor,
                );
              },
            ),

            const SizedBox(height: 20),

            const SensorStatusCard(),

            const SizedBox(height: 20),

            Consumer<CGMProvider>(
              builder: (
                context,
                provider,
                _,
              ) {
                return SyncProgressCard(
                  progress:
                      provider.syncProgress,

                  status:
                      provider
                          .connectionText,

                  color:
                      provider.statusColor,
                );
              },
            ),

            const SizedBox(height: 20),

            Container(
              height: 300,

              padding:
                  const EdgeInsets.all(
                20,
              ),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  24,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(
                      0.04,
                    ),

                    blurRadius: 12,

                    offset:
                        const Offset(
                      0,
                      4,
                    ),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  const Text(
                    "Glucose Trend",

                    style: TextStyle(
                      fontSize: 18,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Expanded(
                    child: Consumer<
                        CGMDashboardProvider>(
                      builder: (
                        context,
                        provider,
                        _,
                      ) {
                        return GlucoseChart(
                          spots: provider
                              .glucoseSpots,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: buildMetricCard(
                    title:
                        "Time In Range",

                    value: "82%",
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: buildMetricCard(
                    title:
                        "Avg Glucose",

                    value: "128",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(
                20,
              ),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
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
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  buildInsightTile(
                    icon:
                        Icons.trending_up,

                    title:
                        "Glucose Stable",

                    subtitle:
                        "Your glucose remained stable for 82% of the day.",
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  buildInsightTile(
                    icon:
                        Icons.restaurant,

                    title:
                        "Meal Spike Detected",

                    subtitle:
                        "Glucose increased after lunch at 2 PM.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding:
                  const EdgeInsets.all(
                20,
              ),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  24,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(
                      0.04,
                    ),

                    blurRadius: 12,

                    offset:
                        const Offset(
                      0,
                      4,
                    ),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  const Text(
                    "Recent Activities",

                    style: TextStyle(
                      fontSize: 18,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  buildActivityTile(
                    icon:
                        Icons.restaurant,

                    title:
                        "Lunch Added",

                    subtitle:
                        "45g carbs",
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  buildActivityTile(
                    icon: Icons
                        .fitness_center,

                    title:
                        "Workout Completed",

                    subtitle:
                        "30 mins",
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  buildActivityTile(
                    icon:
                        Icons.water_drop,

                    title:
                        "Insulin Logged",

                    subtitle:
                        "5 Units",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildMetricCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          24,
        ),
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

  static Widget buildActivityTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor:
              Colors.blue.shade50,

          child: Icon(
            icon,

            color: Colors.blue,
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

              const SizedBox(height: 4),

              Text(
                subtitle,

                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        const Text(
          "Now",

          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  static Widget buildInsightTile({
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
              const EdgeInsets.all(
            12,
          ),

          decoration: BoxDecoration(
            color:
                Colors.blue.shade50,

            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),

          child: Icon(
            icon,

            color:
                Colors.blue.shade700,
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

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}