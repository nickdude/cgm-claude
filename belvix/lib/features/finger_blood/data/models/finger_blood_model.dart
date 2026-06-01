import 'package:intl/intl.dart';

class FingerBloodModel {
  final String id;

  final int glucoseValue;

  final String notes;

  final DateTime loggedAt;

  FingerBloodModel({
    required this.id,
    required this.glucoseValue,
    required this.notes,
    required this.loggedAt,
  });

  String get time =>
      DateFormat('h:mm a').format(loggedAt.toLocal());

  factory FingerBloodModel.fromJson(Map<String, dynamic> json) {
    final raw = json["loggedAt"] ?? json["createdAt"];
    final parsed = raw is String
        ? (DateTime.tryParse(raw) ?? DateTime.now())
        : DateTime.now();

    return FingerBloodModel(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      glucoseValue: (json["glucoseValue"] as num? ?? 0).round(),
      notes: json["notes"] ?? "",
      loggedAt: parsed,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        "glucoseValue": glucoseValue,
        "notes": notes,
        "loggedAt": loggedAt.toUtc().toIso8601String(),
      };
}
