import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/insulin_provider.dart';

class InsulinScreen
    extends StatefulWidget {
  const InsulinScreen({
    super.key,
  });

  @override
  State<InsulinScreen> createState() =>
      _InsulinScreenState();
}

class _InsulinScreenState
    extends State<InsulinScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context
          .read<
              InsulinProvider>()
          .fetchInsulins();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<
            InsulinProvider>();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Insulin"),
      ),

      body: provider.insulins.isEmpty
          ? (provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : const EmptyState(
                    icon: Icons.vaccines_outlined,
                    title: 'No insulin logged yet',
                    message:
                        'Your insulin doses will appear here.\n'
                        'Tap + to add your first one.',
                  ))
          : ListView.builder(
        padding:
            const EdgeInsets.all(20),

        itemCount:
            provider.insulins.length,

        itemBuilder: (context, index) {
          final insulin =
              provider.insulins[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppSurface(
              padding: const EdgeInsets.all(16),
              radius: 20,
              child: Row(
              children: [
                Material(
                  color: Colors.purple.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    height: 60,
                    width: 60,
                    child: Center(
                      child: Icon(
                        Icons.water_drop,
                        color: Colors.purple.shade700,
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
                        insulin
                            .insulinType,

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

                      Text(
                        "${insulin.dosage} Units",
                      ),
                    ],
                  ),
                ),

                Text(insulin.time),
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
                    const AddInsulinDialog(),
          );
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddInsulinDialog
    extends StatefulWidget {
  const AddInsulinDialog({
    super.key,
    this.initialTime,
  });

  /// When set, the entry is logged at this instant instead of "now".
  final DateTime? initialTime;

  @override
  State<AddInsulinDialog>
      createState() =>
          _AddInsulinDialogState();
}

class _AddInsulinDialogState
    extends State<AddInsulinDialog> {
  final dosageController =
      TextEditingController();

  String insulinType = "Rapid";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          const Text("Add Insulin"),

      content: Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          DropdownButtonFormField(
            value: insulinType,

            items: const [
              DropdownMenuItem(
                value: "Rapid",

                child: Text(
                  "Rapid",
                ),
              ),

              DropdownMenuItem(
                value: "Long Acting",

                child: Text(
                  "Long Acting",
                ),
              ),
            ],

            onChanged: (value) {
              insulinType = value!;
            },
          ),

          const SizedBox(height: 20),

          TextField(
            controller:
                dosageController,

            keyboardType:
                TextInputType.number,

            decoration:
                const InputDecoration(
              hintText:
                  "Dosage Units",
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
                    InsulinProvider>()
                .addInsulin(
                  insulinType:
                      insulinType,

                  dosage: int.parse(
                    dosageController
                        .text,
                  ),

                  loggedAt: widget
                      .initialTime,
                );

            Navigator.pop(context);
          },

          child: const Text(
            "Save",
          ),
        ),
      ],
    );
  }
}