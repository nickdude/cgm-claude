import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/custom_textfield.dart';

import '../../../../core/widgets/primary_button.dart';

import '../providers/exercise_provider.dart';

class AddExerciseBottomSheet
    extends StatefulWidget {
  const AddExerciseBottomSheet({
    super.key,
  });

  @override
  State<AddExerciseBottomSheet>
      createState() =>
          _AddExerciseBottomSheetState();
}

class _AddExerciseBottomSheetState
    extends State<AddExerciseBottomSheet> {
  final titleController =
      TextEditingController();

  final durationController =
      TextEditingController();

  final caloriesController =
      TextEditingController();

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
              "Add Exercise",

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

              hint: "Workout Name",
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller:
                  durationController,

              hint:
                  "Duration (min)",

              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller:
                  caloriesController,

              hint:
                  "Calories Burned",

              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              title:
                  "Save Exercise",

              onTap: () async {
                await context
                    .read<
                        ExerciseProvider>()
                    .addExercise(
                      title:
                          titleController
                              .text,

                      duration:
                          int.parse(
                        durationController
                            .text,
                      ),

                      caloriesBurned:
                          int.parse(
                        caloriesController
                            .text,
                      ),
                    );

                Navigator.pop(
                  context,
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}