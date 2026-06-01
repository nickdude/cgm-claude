import 'package:intl/intl.dart';

class FoodModel {
  final String id;

  final String title;

  final int calories;

  final int carbs;

  final int protein;

  final int fat;

  final int fiber;

  final String image;

  /// When the food was logged (UTC from the backend).
  final DateTime loggedAt;

  FoodModel({
    required this.id,
    required this.title,
    required this.calories,
    required this.carbs,
    this.protein = 0,
    this.fat = 0,
    this.fiber = 0,
    this.image = "",
    required this.loggedAt,
  });

  /// Display time in the device's local timezone (e.g. "1:00 PM").
  String get time =>
      DateFormat('h:mm a').format(loggedAt.toLocal());

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    final raw = json["loggedAt"] ?? json["createdAt"];
    final parsed = raw is String
        ? (DateTime.tryParse(raw) ?? DateTime.now())
        : DateTime.now();

    int asInt(dynamic v) => (v as num? ?? 0).round();

    return FoodModel(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      title: json["title"] ?? "",
      calories: asInt(json["calories"]),
      carbs: asInt(json["carbs"]),
      protein: asInt(json["protein"]),
      fat: asInt(json["fat"]),
      fiber: asInt(json["fiber"]),
      image: json["image"] ?? "",
      loggedAt: parsed,
    );
  }

  /// Payload for POST /food/create.
  Map<String, dynamic> toCreateJson() => {
        "title": title,
        "calories": calories,
        "carbs": carbs,
        "protein": protein,
        "fat": fat,
        "fiber": fiber,
        "loggedAt": loggedAt.toUtc().toIso8601String(),
        if (image.isNotEmpty) "image": image,
      };
}
