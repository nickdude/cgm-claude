import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/edit_delete_menu.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/event_time_label.dart';
import '../../data/models/food_model.dart';
import '../providers/food_provider.dart';

import '../widgets/add_food_bottomsheet.dart';

class FoodScreen
    extends StatefulWidget {
  const FoodScreen({
    super.key,
  });

  @override
  State<FoodScreen> createState() =>
      _FoodScreenState();
}

class _FoodScreenState
    extends State<FoodScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context
          .read<FoodProvider>()
          .fetchFoods();
    });
  }

  /// Opens the add/edit sheet. Pass [editing] to reuse the same form in
  /// edit mode (pre-filled, saves via the update API).
  void _openSheet({FoodModel? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (_) => AddFoodBottomSheet(editing: editing),
    );
  }

  Future<void> _confirmDelete(FoodModel food) async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Delete food?",
      message:
          "\"${food.title}\" will be permanently removed. This can't be undone.",
    );

    if (!confirmed || !mounted) return;

    final ok = await context.read<FoodProvider>().deleteFood(food.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? "Food deleted" : "Couldn't delete. Try again.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<FoodProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Food"),
      ),

      body: provider.foods.isEmpty
          ? (provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : const EmptyState(
                    icon: Icons.restaurant_menu_outlined,
                    title: 'No food added yet',
                    message:
                        'Your logged meals will appear here.\n'
                        'Tap + to add your first one.',
                  ))
          : ListView.builder(
        padding:
            const EdgeInsets.all(20),

        itemCount:
            provider.foods.length,

        itemBuilder: (context, index) {
          final food =
              provider.foods[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppSurface(
              padding: const EdgeInsets.all(16),
              radius: 20,
              child: Row(
              children: [
                Material(
                  color: Colors.orange.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    height: 60,
                    width: 60,
                    child: Center(
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.orange.shade700,
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
                        food.title,

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
                        "${food.calories} cal • ${food.carbs}g carbs",
                      ),
                    ],
                  ),
                ),

                EventTimeLabel(food.loggedAt.toLocal()),

                EditDeleteMenu(
                  onEdit: () => _openSheet(editing: food),
                  onDelete: () => _confirmDelete(food),
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