import 'package:intl/intl.dart';

class ExerciseModel {
  final String id;

  /// Maps to the backend `activityType` field.
  final String title;

  final int duration;

  final int caloriesBurned;

  final String image;

  final DateTime loggedAt;

  ExerciseModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.caloriesBurned,
    this.image = "",
    required this.loggedAt,
  });

  String get time =>
      DateFormat('h:mm a').format(loggedAt.toLocal());

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    final raw = json["loggedAt"] ?? json["createdAt"];
    final parsed = raw is String
        ? (DateTime.tryParse(raw) ?? DateTime.now())
        : DateTime.now();

    int asInt(dynamic v) => (v as num? ?? 0).round();

    return ExerciseModel(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      title: json["activityType"] ?? json["title"] ?? "",
      duration: asInt(json["duration"]),
      caloriesBurned: asInt(json["caloriesBurned"]),
      image: json["image"] ?? "",
      loggedAt: parsed,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        "activityType": title,
        "duration": duration,
        "caloriesBurned": caloriesBurned,
        if (image.isNotEmpty) "image": image,
      };
}
