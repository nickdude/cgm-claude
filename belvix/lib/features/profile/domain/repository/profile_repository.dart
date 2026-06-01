import '../../data/models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> getProfile();

  Future<String> uploadProfileImage({
    required List<int> bytes,
    required String filename,
  });

  Future<void> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String profileImage,
  });
}
