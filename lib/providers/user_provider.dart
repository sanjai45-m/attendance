import 'dart:async';
import 'package:flutter/material.dart';
import 'package:attendance/models/user_model.dart';
import 'package:attendance/services/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<UserModel> _employees = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  List<UserModel> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Start listening to employee list
  void loadEmployees() {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _firestoreService.streamEmployees().listen(
      (list) {
        _employees = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load employees.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Update employee details
  Future<bool> updateEmployee(String uid, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updateUser(uid, data);
      return true;
    } catch (e) {
      _error = 'Failed to update employee.';
      notifyListeners();
      return false;
    }
  }

  /// Delete employee
  Future<bool> deleteEmployee(String uid) async {
    try {
      await _firestoreService.deleteUser(uid);
      return true;
    } catch (e) {
      _error = 'Failed to delete employee.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
