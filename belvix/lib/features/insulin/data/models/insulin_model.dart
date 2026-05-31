import 'package:intl/intl.dart';

class InsulinModel {
  final String id;

  final String insulinType;

  final int dosage;

  final DateTime loggedAt;

  InsulinModel({
    required this.id,
    required this.insulinType,
    required this.dosage,
    required this.loggedAt,
  });

  String get time =>
      DateFormat('h:mm a').format(loggedAt.toLocal());

  factory InsulinModel.fromJson(Map<String, dynamic> json) {
    final raw = json["loggedAt"] ?? json["createdAt"];
    final parsed = raw is String
        ? (DateTime.tryParse(raw) ?? DateTime.now())
        : DateTime.now();

    return InsulinModel(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      insulinType: json["insulinType"] ?? "",
      dosage: (json["dosage"] as num? ?? 0).round(),
      loggedAt: parsed,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        "insulinType": insulinType,
        "dosage": dosage,
      };
}
