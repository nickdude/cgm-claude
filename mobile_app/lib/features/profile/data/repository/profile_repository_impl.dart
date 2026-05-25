import '../../domain/repository/profile_repository.dart';

import '../datasource/profile_remote_datasource.dart';

import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource remoteDatasource = ProfileRemoteDatasource();

  @override
  Future<String> uploadProfileImage({required String filePath}) async {
    return remoteDatasource.uploadProfileImage(filePath: filePath);
  }

  @override
  Future<ProfileModel> getProfile() async {
    final response = await remoteDatasource.getProfile();

    return ProfileModel.fromJson(response.data["data"]);
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String profileImage,
  }) async {
    await remoteDatasource.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      profileImage: profileImage,
    );
  }
}
