import '../../data/models/login_model.dart';
import '../repository/auth_repository.dart';

class FacebookLoginUsecase {
  final AuthRepository repository;

  FacebookLoginUsecase(this.repository);

  Future<LoginModel> call({required String accessToken}) async {
    return await repository.loginWithFacebook(accessToken: accessToken);
  }
}