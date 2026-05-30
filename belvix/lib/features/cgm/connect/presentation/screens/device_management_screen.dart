import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/cgm_provider.dart';

class DeviceManagementScreen
    extends StatefulWidget {
  const DeviceManagementScreen({
    super.key,
  });

  @override
  State<DeviceManagementScreen>
      createState() =>
          _DeviceManagementScreenState();
}

class _DeviceManagementScreenState
    extends State<DeviceManagementScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context
          .read<CGMProvider>()
          .fetchDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<CGMProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "CGM Devices",
        ),
      ),

      body: ListView.builder(
        padding:
            const EdgeInsets.all(20),

        itemCount:
            provider.devices.length,

        itemBuilder: (
          context,
          index,
        ) {
          final device =
              provider.devices[index];

          final daysLeft =
              device.expiresAt
                  .difference(
                    DateTime.now(),
                  )
                  .inDays;

          return Container(
            margin:
                const EdgeInsets.only(
              bottom: 16,
            ),

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
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),

                      decoration:
                          BoxDecoration(
                        color: Colors.blue
                            .shade50,

                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),

                      child: Icon(
                        Icons.sensors,

                        color: Colors
                            .blue
                            .shade700,
                      ),
                    ),

                    const SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Text(
                            device
                                .deviceName,

                            style:
                                const TextStyle(
                              fontSize:
                                  18,

                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            device
                                .serialNumber,
                          ),
                        ],
                      ),
                    ),

                    if (device.isActive)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal:
                              12,
                          vertical: 6,
                        ),

                        decoration:
                            BoxDecoration(
                          color: Colors
                              .green
                              .shade100,

                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),

                        child: Text(
                          "ACTIVE",

                          style: TextStyle(
                            color: Colors
                                .green
                                .shade700,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [
                    Text(
                      "Manufacturer",
                    ),

                    Text(
                      device
                          .manufacturer,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [
                    Text("Expires In"),

                    Text(
                      "$daysLeft days",
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (!device.isActive)
                  SizedBox(
                    width:
                        double.infinity,

                    child: ElevatedButton(
                      onPressed: () async {
                        await provider
                            .switchDevice(
                          device,
                        );
                      },

                      child: const Text(
                        "Switch Device",
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}