class UserModel {
  final String id;

  final String fullName;

  final String phoneNumber;

  final String email;

  final String profileImage;

  final bool isProfileCompleted;

  final bool isOnboardingCompleted;

  final bool isCgmConnected;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.profileImage,
    required this.isProfileCompleted,
    required this.isOnboardingCompleted,
    required this.isCgmConnected,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json["_id"] ?? json["id"] ?? "").toString(),

      fullName: json["fullName"] ?? "",

      phoneNumber: json["phoneNumber"] ?? "",

      email: json["email"] ?? "",

      profileImage: json["profileImage"] ?? "",

      isProfileCompleted: json["isProfileCompleted"] ?? false,

      isOnboardingCompleted: json["isOnboardingCompleted"] ?? false,

      isCgmConnected: json["isCgmConnected"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "fullName": fullName,
      "phoneNumber": phoneNumber,
      "email": email,
      "profileImage": profileImage,
      "isProfileCompleted": isProfileCompleted,
      "isOnboardingCompleted": isOnboardingCompleted,
      "isCgmConnected": isCgmConnected,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? profileImage,
    bool? isProfileCompleted,
    bool? isOnboardingCompleted,
    bool? isCgmConnected,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      isCgmConnected: isCgmConnected ?? this.isCgmConnected,
    );
  }
}
