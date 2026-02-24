import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attendance/models/user_model.dart';
import 'package:attendance/core/enums/user_role.dart';
import 'package:attendance/services/auth_service.dart';
import 'package:attendance/services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FCMService _fcmService = FCMService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  String? get uid => _authService.currentUser?.uid;

  /// Initialize — check if already logged in (auto-login)
  Future<void> initialize() async {
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        _currentUser = await _authService.getUserDoc(firebaseUser.uid);
        if (_currentUser != null) {
          await _setupFCM(_currentUser!.uid);
        }
      }
    } catch (e) {
      debugPrint('[AuthProvider] Auto-login failed: $e');
    }
    _isInitialized = true;
    notifyListeners();
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

      // Setup FCM after successful login
      await _setupFCM(_currentUser!.uid);

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

  /// Setup FCM: request permission, save token, listen for refresh, handle foreground
  Future<void> _setupFCM(String uid) async {
    try {
      await _fcmService.requestPermission();
      await _fcmService.saveTokenToFirestore(uid);
      _fcmService.listenForTokenRefresh(uid);

      // Handle foreground notifications
      _fcmService.setupForegroundHandler((message) {
        debugPrint(
          '[AuthProvider] Foreground notification: ${message.notification?.title}',
        );
      });
    } catch (e) {
      debugPrint('[AuthProvider] FCM setup error: $e');
    }
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
