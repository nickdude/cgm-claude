import '../../data/models/login_model.dart';
import '../repository/auth_repository.dart';

class GoogleLoginUsecase {
  final AuthRepository repository;

  GoogleLoginUsecase(this.repository);

  Future<LoginModel> call({required String idToken}) async {
    return await repository.loginWithGoogle(idToken: idToken);
  }
}