class CGMDeviceModel {
  final String id;

  final String serialNumber;

  final String deviceName;

  final String manufacturer;

  final bool isActive;

  final DateTime connectedAt;

  final DateTime expiresAt;

  CGMDeviceModel({
    required this.id,
    required this.serialNumber,
    required this.deviceName,
    required this.manufacturer,
    required this.isActive,
    required this.connectedAt,
    required this.expiresAt,
  });

  factory CGMDeviceModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CGMDeviceModel(
      id: (json["_id"] ??
              json["id"] ??
              "")
          .toString(),
      serialNumber:
          json["serialNumber"] ?? "",
      deviceName:
          json["deviceName"] ?? "",
      manufacturer:
          json["manufacturer"] ?? "",
      isActive:
          json["isActive"] ?? false,
      connectedAt: DateTime.parse(
        json["connectedAt"],
      ),
      expiresAt: DateTime.parse(
        json["expiresAt"],
      ),
    );
  }

  CGMDeviceModel copyWith({
    String? id,
    String? serialNumber,
    String? deviceName,
    String? manufacturer,
    bool? isActive,
    DateTime? connectedAt,
    DateTime? expiresAt,
  }) {
    return CGMDeviceModel(
      id: id ?? this.id,
      serialNumber: serialNumber ??
          this.serialNumber,
      deviceName:
          deviceName ?? this.deviceName,
      manufacturer: manufacturer ??
          this.manufacturer,
      isActive:
          isActive ?? this.isActive,
      connectedAt: connectedAt ??
          this.connectedAt,
      expiresAt:
          expiresAt ?? this.expiresAt,
    );
  }
}
