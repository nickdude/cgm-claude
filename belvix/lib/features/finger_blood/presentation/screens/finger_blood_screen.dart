import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/finger_blood_provider.dart';

class FingerBloodScreen
    extends StatefulWidget {
  const FingerBloodScreen({
    super.key,
  });

  @override
  State<FingerBloodScreen>
      createState() =>
          _FingerBloodScreenState();
}

class _FingerBloodScreenState
    extends State<FingerBloodScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context
          .read<
              FingerBloodProvider>()
          .fetchFingerBloods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<
            FingerBloodProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Glucose Meter",
        ),
      ),

      body: provider.fingerBloods.isEmpty
          ? (provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : const EmptyState(
                    icon: Icons.water_drop_outlined,
                    title: 'No readings logged yet',
                    message:
                        'Your finger-stick readings will appear here.\n'
                        'Tap + to add your first one.',
                  ))
          : ListView.builder(
        padding:
            const EdgeInsets.all(20),

        itemCount:
            provider.fingerBloods
                .length,

        itemBuilder: (
          context,
          index,
        ) {
          final item =
              provider
                  .fingerBloods[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppSurface(
              padding: const EdgeInsets.all(16),
              radius: 20,
              child: Row(
              children: [
                Material(
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    height: 60,
                    width: 60,
                    child: Center(
                      child: Icon(
                        Icons.bloodtype,
                        color: Colors.red.shade700,
                      ),
                    ),
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
                        "${item.glucoseValue} mg/dL",

                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,

                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(item.notes),
                    ],
                  ),
                ),

                Text(item.time),
              ],
            ),
            ),
          );
        },
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,

            builder:
                (_) =>
                    const AddFingerBloodDialog(),
          );
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddFingerBloodDialog
    extends StatefulWidget {
  const AddFingerBloodDialog({
    super.key,
    this.initialTime,
  });

  /// When set, the entry is logged at this instant instead of "now".
  final DateTime? initialTime;

  @override
  State<AddFingerBloodDialog>
      createState() =>
          _AddFingerBloodDialogState();
}

class _AddFingerBloodDialogState
    extends State<AddFingerBloodDialog> {
  final glucoseController =
      TextEditingController();

  final notesController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Add Glucose Meter Reading",
      ),

      content: Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          TextField(
            controller:
                glucoseController,

            keyboardType:
                TextInputType.number,

            decoration:
                const InputDecoration(
              hintText:
                  "Glucose Value",
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller:
                notesController,

            decoration:
                const InputDecoration(
              hintText: "Notes",
            ),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },

          child: const Text(
            "Cancel",
          ),
        ),

        ElevatedButton(
          onPressed: () async {
            await context
                .read<
                    FingerBloodProvider>()
                .addFingerBlood(
                  glucoseValue:
                      int.parse(
                    glucoseController
                        .text,
                  ),

                  notes:
                      notesController
                          .text,

                  loggedAt: widget
                      .initialTime,
                );

            Navigator.pop(
              context,
            );
          },

          child: const Text(
            "Save",
          ),
        ),
      ],
    );
  }
}