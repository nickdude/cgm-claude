import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/custom_textfield.dart';

import '../../../../core/widgets/primary_button.dart';

import '../../data/models/exercise_model.dart';

import '../providers/exercise_provider.dart';

class AddExerciseBottomSheet
    extends StatefulWidget {
  const AddExerciseBottomSheet({
    super.key,
    this.initialTime,
    this.editing,
  });

  /// When set, the entry is logged at this instant instead of "now".
  final DateTime? initialTime;

  /// When set, the sheet opens in edit mode pre-filled with this record and
  /// the save button calls the update API instead of create.
  final ExerciseModel? editing;

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

  bool _saving = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();

    // Pre-populate the form when editing an existing record.
    final editing = widget.editing;
    if (editing != null) {
      titleController.text = editing.title;
      durationController.text = editing.duration.toString();
      caloriesController.text = editing.caloriesBurned.toString();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    durationController.dispose();
    caloriesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;

    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a workout name")),
      );
      return;
    }

    final duration = int.tryParse(durationController.text.trim()) ?? 0;
    final calories = int.tryParse(caloriesController.text.trim()) ?? 0;

    setState(() => _saving = true);

    final provider = context.read<ExerciseProvider>();

    final ok = _isEditing
        ? await provider.updateExercise(
            id: widget.editing!.id,
            title: title,
            duration: duration,
            caloriesBurned: calories,
            loggedAt: widget.editing!.loggedAt,
          )
        : await provider.addExercise(
            title: title,
            duration: duration,
            caloriesBurned: calories,
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
                ? "Couldn't update exercise. Try again."
                : "Couldn't save exercise. Try again.",
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
              _isEditing ? "Edit Exercise" : "Add Exercise",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            CustomTextField(
              controller: titleController,
              hint: "Workout Name",
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller: durationController,
              hint: "Duration (min)",
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller: caloriesController,
              hint: "Calories Burned",
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              title: _isEditing ? "Update Exercise" : "Save Exercise",
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
