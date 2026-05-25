class FoodModel {
  final String id;

  final String title;

  final int calories;

  final int carbs;

  final String image;

  final String time;

  FoodModel({
    required this.id,
    required this.title,
    required this.calories,
    required this.carbs,
    required this.image,
    required this.time,
  });

  factory FoodModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return FoodModel(
      id: json["_id"],

      title: json["title"],

      calories: json["calories"],

      carbs: json["carbs"],

      image: json["image"] ?? "",

      time: json["time"] ?? "",
    );
  }
}