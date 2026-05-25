import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

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

      body: ListView.builder(
        padding:
            const EdgeInsets.all(20),

        itemCount:
            provider.insulins.length,

        itemBuilder: (context, index) {
          final insulin =
              provider.insulins[index];

          return Container(
            margin:
                const EdgeInsets.only(
              bottom: 16,
            ),

            padding:
                const EdgeInsets.all(
              16,
            ),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),

            child: Row(
              children: [
                Container(
                  height: 60,
                  width: 60,

                  decoration: BoxDecoration(
                    color: Colors
                        .purple.shade50,

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),

                  child: Icon(
                    Icons.water_drop,

                    color:
                        Colors.purple
                            .shade700,
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
  });

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