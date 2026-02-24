import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attendance/models/user_model.dart';
import 'package:attendance/core/enums/user_role.dart';
import 'package:attendance/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  String? get uid => _authService.currentUser?.uid;

  /// Initialize — check if already logged in
  Future<void> initialize() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _currentUser = await _authService.getUserDoc(firebaseUser.uid);
      notifyListeners();
    }
  }

  /// Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(email, password);
      if (_currentUser == null) {
        _error = 'User profile not found. Contact admin.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _parseAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _error = 'Failed to send reset email.';
      notifyListeners();
      return false;
    }
  }

  /// Create employee (admin only)
  Future<UserModel?> createEmployee({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String employeeId,
    required String department,
    String role = 'employee',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.createEmployeeAccount(
        email: email,
        password: password,
        name: name,
        phone: phone,
        employeeId: employeeId,
        department: department,
        role: role,
      );
      _isLoading = false;
      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      _error = _parseAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to create employee.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _parseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
