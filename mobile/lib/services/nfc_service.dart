import '../models/nfc_tag.dart';
import '../utils/api_config.dart';
import 'api_service.dart';

/// NFC Service for tag management and scanning
class NFCService {
  final ApiService _api = ApiService();

  /// Get all user's NFC tags
  Future<List<NFCTag>> getTags() async {
    try {
      final response = await _api.get(ApiConfig.nfcTags);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((tag) => NFCTag.fromJson(tag))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Register new NFC tag
  Future<Map<String, dynamic>> registerTag(String tagUid) async {
    try {
      print('Registering NFC tag: $tagUid');
      print('Endpoint: ${ApiConfig.nfcRegister}');

      final requestData = {
        'tag_uid': tagUid,
        'tag_type': 'NTAG215',
      };
      print('Request data: $requestData');

      final response = await _api.post(
        ApiConfig.nfcRegister,
        data: requestData,
      );

      print('Register response status: ${response.statusCode}');
      print('Register response data: ${response.data}');

      if (response.statusCode == 201) {
        return {
          'success': true,
          'tag': NFCTag.fromJson(response.data),
        };
      }
      return {'success': false, 'error': 'Failed to register tag'};
    } on Exception catch (e) {
      print('Register tag error: $e');
      print('Error type: ${e.runtimeType}');

      String errorMessage = e.toString();

      // Try to extract meaningful error from Dio exception
      if (e.toString().contains('400')) {
        errorMessage = 'Bad request - check if tag format is correct';
      }

      return {'success': false, 'error': errorMessage};
    }
  }

  /// Scan NFC tag (authenticated)
  Future<Map<String, dynamic>> scanTag(String tagUid) async {
    try {
      final response = await _api.post(
        ApiConfig.nfcScan,
        data: {'tag_uid': tagUid},
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'error': 'Failed to scan tag'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Revoke NFC tag
  Future<bool> revokeTag(int tagId, String? reason) async {
    try {
      final response = await _api.post(
        ApiConfig.nfcRevoke,
        data: {
          'tag_id': tagId,
          if (reason != null) 'reason': reason,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get access logs
  Future<List<NFCAccessLog>> getAccessLogs() async {
    try {
      final response = await _api.get(ApiConfig.nfcAccessLogs);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((log) => NFCAccessLog.fromJson(log))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get emergency access data (public endpoint)
  Future<Map<String, dynamic>?> getEmergencyAccess(String tagUid) async {
    try {
      final response = await _api.get(ApiConfig.nfcEmergency(tagUid));
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
