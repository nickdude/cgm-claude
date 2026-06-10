import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/custom_textfield.dart';

import '../../../../core/widgets/primary_button.dart';

import '../../data/models/food_model.dart';

import '../providers/food_provider.dart';

class AddFoodBottomSheet
    extends StatefulWidget {
  const AddFoodBottomSheet({
    super.key,
    this.initialTime,
    this.editing,
  });

  /// When set, the entry is logged at this instant instead of "now".
  final DateTime? initialTime;

  /// When set, the sheet opens in edit mode pre-filled with this record and
  /// the save button calls the update API instead of create.
  final FoodModel? editing;

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

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();

    // Pre-populate the form when editing an existing record.
    final editing = widget.editing;
    if (editing != null) {
      titleController.text = editing.title;
      caloriesController.text = editing.calories.toString();
      carbsController.text = editing.carbs.toString();
      proteinController.text = editing.protein.toString();
      fatController.text = editing.fat.toString();
      fiberController.text = editing.fiber.toString();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    caloriesController.dispose();
    carbsController.dispose();
    proteinController.dispose();
    fatController.dispose();
    fiberController.dispose();
    super.dispose();
  }

  int _parse(TextEditingController c) =>
      int.tryParse(c.text.trim()) ?? 0;

  Future<void> _submit() async {
    if (_saving) return;

    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a food name")),
      );
      return;
    }

    setState(() => _saving = true);

    final provider = context.read<FoodProvider>();

    final ok = _isEditing
        ? await provider.updateFood(
            id: widget.editing!.id,
            title: title,
            calories: _parse(caloriesController),
            carbs: _parse(carbsController),
            protein: _parse(proteinController),
            fat: _parse(fatController),
            fiber: _parse(fiberController),
            loggedAt: widget.editing!.loggedAt,
          )
        : await provider.addFood(
            title: title,
            calories: _parse(caloriesController),
            carbs: _parse(carbsController),
            protein: _parse(proteinController),
            fat: _parse(fatController),
            fiber: _parse(fiberController),
            loggedAt: widget.initialTime,
          );

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? "Couldn't update food. Try again."
                : "Couldn't save food. Try again.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? "Edit Food" : "Add Food",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            CustomTextField(
              controller: titleController,
              hint: "Food Name",
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller: caloriesController,
              hint: "Calories",
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller: carbsController,
              hint: "Carbs (g)",
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller: proteinController,
              hint: "Protein (g)",
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller: fatController,
              hint: "Fat (g)",
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller: fiberController,
              hint: "Fiber (g)",
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              title: _isEditing ? "Update Food" : "Save Food",
              isLoading: _saving,
              onTap: _submit,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
