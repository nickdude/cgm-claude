import 'package:flutter/material.dart';

import '../../data/models/finger_blood_model.dart';
import '../../data/repository/finger_blood_repository_impl.dart';

class FingerBloodProvider extends ChangeNotifier {
  final FingerBloodRepository _repository = FingerBloodRepository();

  bool isLoading = false;

  List<FingerBloodModel> fingerBloods = [];

  Future<void> fetchFingerBloods() async {
    isLoading = true;
    notifyListeners();

    fingerBloods = await _repository.list();

    isLoading = false;
    notifyListeners();
  }

  Future<bool> addFingerBlood({
    required int glucoseValue,
    required String notes,
    DateTime? loggedAt,
  }) async {
    final created = await _repository.create(
      FingerBloodModel(
        id: "",
        glucoseValue: glucoseValue,
        notes: notes,
        loggedAt: loggedAt ?? DateTime.now(),
      ),
    );

    if (created == null) return false;

    fingerBloods.insert(0, created);
    notifyListeners();
    return true;
  }

  Future<void> deleteFingerBlood(String id) async {
    final ok = await _repository.delete(id);
    if (ok) {
      fingerBloods.removeWhere((f) => f.id == id);
      notifyListeners();
    }
  }
}
