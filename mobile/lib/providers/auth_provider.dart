import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Authentication Provider
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  /// Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    _isLoading = false;
    if (result['success']) {
      _user = User.fromJson(result['user']);
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  /// Register
  Future<bool> register({
    required String email,
    required String password,
    required String password2,
    required String firstName,
    required String lastName,
    String? middleName,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.register(
      email: email,
      password: password,
      password2: password2,
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      phone: phone,
    );

    _isLoading = false;
    if (result['success']) {
      _user = User.fromJson(result['user']);
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  /// Check authentication on app start
  Future<void> checkAuth() async {
    final isAuth = await _authService.isAuthenticated();
    if (!isAuth) {
      _user = null;
    }
    // TODO: Fetch current user data if authenticated
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
