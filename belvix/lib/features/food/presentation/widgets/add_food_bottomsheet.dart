import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/custom_textfield.dart';

import '../../../../core/widgets/primary_button.dart';

import '../providers/food_provider.dart';

class AddFoodBottomSheet
    extends StatefulWidget {
  const AddFoodBottomSheet({
    super.key,
    this.initialTime,
  });

  /// When set, the entry is logged at this instant instead of "now".
  final DateTime? initialTime;

  @override
  State<AddFoodBottomSheet>
      createState() =>
          _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState
    extends State<AddFoodBottomSheet> {
  final titleController =
      TextEditingController();

  final caloriesController =
      TextEditingController();

  final carbsController =
      TextEditingController();

  final proteinController =
      TextEditingController();

  final fatController =
      TextEditingController();

  final fiberController =
      TextEditingController();

  bool _saving = false;

  int _parse(TextEditingController c) =>
      int.tryParse(c.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            MediaQuery.of(context)
                .viewInsets
                .bottom,
      ),

      child: SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              "Add Food",

              style: TextStyle(
                fontSize: 28,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            CustomTextField(
              controller:
                  titleController,

              hint: "Food Name",
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller:
                  caloriesController,

              hint: "Calories",

              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller:
                  carbsController,

              hint: "Carbs (g)",

              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller:
                  proteinController,

              hint: "Protein (g)",

              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller: fatController,

              hint: "Fat (g)",

              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller:
                  fiberController,

              hint: "Fiber (g)",

              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              title:
                  _saving ? "Saving…" : "Save Food",

              onTap: () async {
                if (_saving) return;

                final title =
                    titleController.text
                        .trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please enter a food name",
                      ),
                    ),
                  );
                  return;
                }

                setState(
                  () => _saving = true,
                );

                final ok = await context
                    .read<FoodProvider>()
                    .addFood(
                      title: title,
                      calories: _parse(
                        caloriesController,
                      ),
                      carbs: _parse(
                        carbsController,
                      ),
                      protein: _parse(
                        proteinController,
                      ),
                      fat: _parse(
                        fatController,
                      ),
                      fiber: _parse(
                        fiberController,
                      ),
                      loggedAt: widget
                          .initialTime,
                    );

                if (!context.mounted) {
                  return;
                }

                if (ok) {
                  Navigator.pop(context);
                } else {
                  setState(
                    () =>
                        _saving = false,
                  );
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Couldn't save food. Try again.",
                      ),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}