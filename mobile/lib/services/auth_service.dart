import 'package:dio/dio.dart';
import '../utils/api_config.dart';
import 'api_service.dart';

/// Authentication Service
class AuthService {
  final ApiService _api = ApiService();

  /// Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _api.post(
        ApiConfig.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Save tokens
        await _api.saveTokens(
          data['access'],
          data['refresh'],
        );
        return {'success': true, 'user': data['user']};
      }
      return {'success': false, 'error': 'Login failed'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['detail'] ?? 'Login failed',
      };
    } catch (e) {
      return {'success': false, 'error': 'An error occurred'};
    }
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String password2,
    required String firstName,
    required String lastName,
    String? middleName,
    String? phone,
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.register,
        data: {
          'email': email,
          'password': password,
          'password2': password2,
          'first_name': firstName,
          'last_name': lastName,
          if (middleName != null) 'middle_name': middleName,
          if (phone != null) 'phone': phone,
          'role': 'PATIENT', // Default role
        },
      );

      if (response.statusCode == 201) {
        final data = response.data;
        // Save tokens
        await _api.saveTokens(
          data['access'],
          data['refresh'],
        );
        return {'success': true, 'user': data['user']};
      }
      return {'success': false, 'error': 'Registration failed'};
    } on DioException catch (e) {
      final errors = e.response?.data;
      String errorMessage = 'Registration failed';
      if (errors is Map) {
        errorMessage = errors.values.first.toString();
      }
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'An error occurred'};
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _api.post(ApiConfig.logout);
    } catch (e) {
      // Ignore error
    } finally {
      await _api.clearTokens();
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _api.isAuthenticated();
  }
}
