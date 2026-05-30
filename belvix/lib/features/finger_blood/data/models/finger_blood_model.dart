class FingerBloodModel {
  final String id;

  final int glucoseValue;

  final String notes;

  final String time;

  FingerBloodModel({
    required this.id,
    required this.glucoseValue,
    required this.notes,
    required this.time,
  });

  factory FingerBloodModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return FingerBloodModel(
      id: json["_id"],

      glucoseValue:
          json["glucoseValue"],

      notes: json["notes"] ?? "",

      time: json["time"] ?? "",
    );
  }
}