import 'dart:async';
import 'package:flutter/material.dart';
import 'package:attendance/models/app_settings_model.dart';
import 'package:attendance/services/firestore_service.dart';

class SettingsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  AppSettingsModel _settings = AppSettingsModel();
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  AppSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load settings from Firestore (one-time)
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _firestoreService.getSettings();
    } catch (e) {
      _error = 'Failed to load settings.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Stream settings (real-time)
  void streamSettings() {
    _subscription?.cancel();
    _subscription = _firestoreService.streamSettings().listen(
      (settings) {
        _settings = settings;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to stream settings.';
        notifyListeners();
      },
    );
  }

  /// Update settings
  Future<bool> updateSettings(AppSettingsModel newSettings) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.updateSettings(newSettings.toMap());
      _settings = newSettings;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update settings.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
