import 'package:flutter/material.dart';

import '../../data/models/insulin_model.dart';
import '../../data/repository/insulin_repository_impl.dart';

class InsulinProvider extends ChangeNotifier {
  final InsulinRepository _repository = InsulinRepository();

  bool isLoading = false;

  List<InsulinModel> insulins = [];

  Future<void> fetchInsulins() async {
    isLoading = true;
    notifyListeners();

    insulins = await _repository.list();

    isLoading = false;
    notifyListeners();
  }

  Future<bool> addInsulin({
    required String insulinType,
    required int dosage,
  }) async {
    final created = await _repository.create(
      InsulinModel(
        id: "",
        insulinType: insulinType,
        dosage: dosage,
        loggedAt: DateTime.now(),
      ),
    );

    if (created == null) return false;

    insulins.insert(0, created);
    notifyListeners();
    return true;
  }

  Future<void> deleteInsulin(String id) async {
    final ok = await _repository.delete(id);
    if (ok) {
      insulins.removeWhere((i) => i.id == id);
      notifyListeners();
    }
  }
}
