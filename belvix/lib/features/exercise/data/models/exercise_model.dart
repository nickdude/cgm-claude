class ExerciseModel {
  final String id;

  final String title;

  final int duration;

  final int caloriesBurned;

  final String image;

  final String time;

  ExerciseModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.caloriesBurned,
    required this.image,
    required this.time,
  });

  factory ExerciseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExerciseModel(
      id: json["_id"],

      title: json["title"],

      duration: json["duration"],

      caloriesBurned:
          json["caloriesBurned"],

      image: json["image"] ?? "",

      time: json["time"] ?? "",
    );
  }
}