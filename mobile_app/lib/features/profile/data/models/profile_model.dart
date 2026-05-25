class ProfileModel {
  final String id;

  final String fullName;

  final String email;

  final String profileImage;

  final bool isProfileCompleted;

  final bool isOnboardingCompleted;

  ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.profileImage,
    required this.isProfileCompleted,
    required this.isOnboardingCompleted,
  });

  factory ProfileModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProfileModel(
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
    );
  }
}