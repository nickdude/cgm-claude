import '../../data/models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> getProfile();

  Future<String> uploadProfileImage({required String filePath});

  Future<void> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String profileImage,
  });
}
