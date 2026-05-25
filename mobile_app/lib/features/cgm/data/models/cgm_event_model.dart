class CgmEventModel {
  final String type;

  final Map<String, dynamic> data;

  CgmEventModel({
    required this.type,
    required this.data,
  });

  factory CgmEventModel.fromMap(
    Map<dynamic, dynamic> map,
  ) {
    return CgmEventModel(
      type: map["type"],

      data:
          Map<String, dynamic>.from(
        map,
      ),
    );
  }
}