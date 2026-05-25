import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<FoodProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Food"),
      ),

      body: ListView.builder(
        padding:
            const EdgeInsets.all(20),

        itemCount:
            provider.foods.length,

        itemBuilder: (context, index) {
          final food =
              provider.foods[index];

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
                        .orange.shade50,

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),

                  child: Icon(
                    Icons.restaurant,

                    color:
                        Colors.orange
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

                Text(food.time),
              ],
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
                    const AddFoodBottomSheet(),
          );
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}