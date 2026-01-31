import 'package:dio/dio.dart';
import '../utils/api_config.dart';
import 'api_service.dart';

/// Authentication Service
class AuthService {
  final ApiService _api = ApiService();

  /// Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting login to: ${ApiConfig.login}');
      final response = await _api.post(
        ApiConfig.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      print('Login response status: ${response.statusCode}');
      print('Login response data: ${response.data}');

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
      print('Login DioException: ${e.response?.statusCode}');
      print('Login error data: ${e.response?.data}');

      String errorMessage = 'Login failed';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          errorMessage = data['detail']?.toString() ??
                        data['error']?.toString() ??
                        data.values.first.toString();
        } else if (data is String) {
          errorMessage = data;
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Connection error. Check your internet connection.';
      }

      return {'success': false, 'error': errorMessage};
    } catch (e) {
      print('Login unexpected error: $e');
      return {'success': false, 'error': 'An error occurred: $e'};
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
