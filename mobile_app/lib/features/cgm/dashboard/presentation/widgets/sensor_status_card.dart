import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../connect/presentation/providers/cgm_provider.dart';

class SensorStatusCard
    extends StatelessWidget {
  const SensorStatusCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CGMProvider>(
      builder: (
        context,
        provider,
        _,
      ) {
        return Container(
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

          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.all(
                  14,
                ),

                decoration:
                    BoxDecoration(
                  color: provider
                      .statusColor
                      .withOpacity(
                    0.1,
                  ),

                  shape:
                      BoxShape.circle,
                ),

                child: Icon(
                  Icons.sensors,

                  color: provider
                      .statusColor,
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
                      provider
                          .connectionText,

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      provider
                              .activeDevice
                              ?.deviceName ??
                          "No Device",
                    ),
                  ],
                ),
              ),

              Container(
                height: 12,
                width: 12,

                decoration:
                    BoxDecoration(
                  color: provider
                      .statusColor,

                  shape:
                      BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}