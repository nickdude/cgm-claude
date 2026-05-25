import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/custom_textfield.dart';

import '../../../../core/widgets/primary_button.dart';

import '../providers/food_provider.dart';

class AddFoodBottomSheet
    extends StatefulWidget {
  const AddFoodBottomSheet({
    super.key,
  });

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

              hint: "Carbs",

              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              title: "Save Food",

              onTap: () async {
                await context
                    .read<FoodProvider>()
                    .addFood(
                      title:
                          titleController
                              .text,

                      calories:
                          int.parse(
                        caloriesController
                            .text,
                      ),

                      carbs: int.parse(
                        carbsController
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