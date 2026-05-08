import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;
  bool _isSyncing = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isSyncing => _isSyncing;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Check if already logged in on app start
  Future<void> initialize() async {
    final token = await ApiService.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      _user = await ApiService.getMe();
      _status = AuthStatus.authenticated;
    } catch (e) {
      await ApiService.deleteToken();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // Login with GitHub OAuth code (from deep link)
  Future<bool> loginWithCode(String code) async {
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.loginWithCode(code);
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Login failed. Please try again.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Sync GitHub data
  Future<List<dynamic>> syncGitHub() async {
    if (_isSyncing) return [];
    _isSyncing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.syncGitHub();
      _user = result.user;
      _isSyncing = false;
      notifyListeners();
      return result.newAchievements;
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      return [];
    }
  }

  // Update local user data
  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
