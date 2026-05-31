import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/app_surface.dart';
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

      body: ListView.builder(
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

                Text(exercise.time),
              ],
            ),
            ),
          );
        },
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,

            isScrollControlled:
                true,

            backgroundColor:
                Colors.white,

            shape:
                const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(
                  30,
                ),
              ),
            ),

            builder:
                (_) =>
                    const AddExerciseBottomSheet(),
          );
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}