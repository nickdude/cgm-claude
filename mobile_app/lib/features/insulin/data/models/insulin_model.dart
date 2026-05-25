class InsulinModel {
  final String id;

  final String insulinType;

  final int dosage;

  final String time;

  InsulinModel({
    required this.id,
    required this.insulinType,
    required this.dosage,
    required this.time,
  });

  factory InsulinModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return InsulinModel(
      id: json["_id"],

      insulinType:
          json["insulinType"],

      dosage: json["dosage"],

      time: json["time"] ?? "",
    );
  }
}