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
      final response = await _api.post(
        ApiConfig.nfcRegister,
        data: {
          'tag_uid': tagUid,
          'tag_type': 'NTAG215',
        },
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'tag': NFCTag.fromJson(response.data),
        };
      }
      return {'success': false, 'error': 'Failed to register tag'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
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
