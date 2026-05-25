class UserModel {
  final String id;

  final String fullName;

  final String email;

  final String profileImage;

  final bool isProfileCompleted;

  final bool isOnboardingCompleted;

  final bool isCgmConnected;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.profileImage,
    required this.isProfileCompleted,
    required this.isOnboardingCompleted,
    required this.isCgmConnected,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserModel(
      id: json["_id"],

      fullName:
          json["fullName"] ?? "",

      email: json["email"] ?? "",

      profileImage:
          json["profileImage"] ?? "",

      isProfileCompleted:
          json["isProfileCompleted"] ??
              false,

      isOnboardingCompleted:
          json["isOnboardingCompleted"] ??
              false,

      isCgmConnected:
          json["isCgmConnected"] ??
              false,
    );
  }
}