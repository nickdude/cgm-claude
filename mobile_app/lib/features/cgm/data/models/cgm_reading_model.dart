class CgmReadingModel {
  final String? id;

  final String? deviceId;

  /// Glucose value in mg/dL.
  final double glucoseValue;

  final String trend;

  final DateTime readingAt;

  CgmReadingModel({
    this.id,
    this.deviceId,
    required this.glucoseValue,
    required this.trend,
    required this.readingAt,
  });

  factory CgmReadingModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw =
        json["readingAt"] ??
            json["createdAt"];

    final parsed = raw is String
        ? DateTime.tryParse(raw) ??
            DateTime.now()
        : DateTime.now();

    return CgmReadingModel(
      id: (json["_id"] ??
              json["id"])
          ?.toString(),
      deviceId: json["deviceId"]
          ?.toString(),
      glucoseValue:
          (json["glucoseValue"] as num? ??
                  0)
              .toDouble(),
      trend: (json["trend"] ?? "Stable")
          .toString(),
      readingAt: parsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "glucoseValue": glucoseValue,
      "trend": trend,
      "readingAt":
          readingAt.toIso8601String(),
    };
  }
}
