import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/edit_delete_menu.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/event_time_label.dart';
import '../../data/models/exercise_model.dart';
import '../providers/exercise_provider.dart';

import '../widgets/add_exercise_bottomsheet.dart';

class ActivityScreen
    extends StatefulWidget {
  const ActivityScreen({
    super.key,
  });

  @override
  State<ActivityScreen> createState() =>
      _ActivityScreenState();
}

class _ActivityScreenState
    extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context
          .read<
              ExerciseProvider>()
          .fetchExercises();
    });
  }

  /// Opens the add/edit sheet. Pass [editing] to reuse the same form in
  /// edit mode (pre-filled, saves via the update API).
  void _openSheet({ExerciseModel? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (_) => AddExerciseBottomSheet(editing: editing),
    );
  }

  Future<void> _confirmDelete(ExerciseModel exercise) async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Delete exercise?",
      message:
          "\"${exercise.title}\" will be permanently removed. This can't be undone.",
    );

    if (!confirmed || !mounted) return;

    final ok = await context
        .read<ExerciseProvider>()
        .deleteExercise(exercise.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? "Exercise deleted" : "Couldn't delete. Try again.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<
            ExerciseProvider>();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Activities"),
      ),

      body: provider.exercises.isEmpty
          ? (provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : const EmptyState(
                    icon: Icons.directions_run_outlined,
                    title: 'No activity logged yet',
                    message:
                        'Your workouts will appear here.\n'
                        'Tap + to add your first one.',
                  ))
          : ListView.builder(
        padding:
            const EdgeInsets.all(20),

        itemCount:
            provider.exercises.length,

        itemBuilder: (context, index) {
          final exercise =
              provider.exercises[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppSurface(
              padding: const EdgeInsets.all(16),
              radius: 20,
              child: Row(
              children: [
                Material(
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    height: 60,
                    width: 60,
                    child: Center(
                      child: Icon(
                        Icons.fitness_center,
                        color: Colors.blue.shade700,
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
                        exercise.title,

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
                        "${exercise.duration} mins • ${exercise.caloriesBurned} cal",
                      ),
                    ],
                  ),
                ),

                EventTimeLabel(exercise.loggedAt.toLocal()),

                EditDeleteMenu(
                  onEdit: () => _openSheet(editing: exercise),
                  onDelete: () => _confirmDelete(exercise),
                ),
              ],
            ),
            ),
          );
        },
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: () => _openSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
}