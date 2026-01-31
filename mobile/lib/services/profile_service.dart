import 'package:dio/dio.dart';
import '../models/medical_profile.dart';
import '../utils/api_config.dart';
import 'api_service.dart';

/// Profile Service for medical profile management
class ProfileService {
  final ApiService _api = ApiService();

  /// Get current user's profile
  Future<MedicalProfile?> getProfile() async {
    try {
      final response = await _api.get(ApiConfig.profile);
      if (response.statusCode == 200 && response.data != null) {
        return MedicalProfile.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create or update profile
  Future<bool> saveProfile(MedicalProfile profile) async {
    try {
      final response = profile.id == null
          ? await _api.post(ApiConfig.profile, data: profile.toJson())
          : await _api.put(ApiConfig.profile, data: profile.toJson());

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Allergies
  Future<List<Allergy>> getAllergies() async {
    try {
      final response = await _api.get(ApiConfig.allergies);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((a) => Allergy.fromJson(a))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addAllergy(Allergy allergy) async {
    try {
      final response =
          await _api.post(ApiConfig.allergies, data: allergy.toJson());
      return response.statusCode == 201;
    } on DioException {
      return false;
    }
  }

  Future<bool> updateAllergy(Allergy allergy) async {
    try {
      final response = await _api.put(
        '${ApiConfig.allergies}${allergy.id}/',
        data: allergy.toJson(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAllergy(int id) async {
    try {
      final response = await _api.delete('${ApiConfig.allergies}$id/');
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // Chronic Diseases
  Future<List<ChronicDisease>> getChronicDiseases() async {
    try {
      final response = await _api.get(ApiConfig.chronicDiseases);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((d) => ChronicDisease.fromJson(d))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addChronicDisease(ChronicDisease disease) async {
    try {
      final response =
          await _api.post(ApiConfig.chronicDiseases, data: disease.toJson());
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateChronicDisease(ChronicDisease disease) async {
    try {
      final response = await _api.put(
        '${ApiConfig.chronicDiseases}${disease.id}/',
        data: disease.toJson(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteChronicDisease(int id) async {
    try {
      final response = await _api.delete('${ApiConfig.chronicDiseases}$id/');
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // Medications
  Future<List<Medication>> getMedications() async {
    try {
      final response = await _api.get(ApiConfig.medications);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((m) => Medication.fromJson(m))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addMedication(Medication medication) async {
    try {
      final response =
          await _api.post(ApiConfig.medications, data: medication.toJson());
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMedication(Medication medication) async {
    try {
      final response = await _api.put(
        '${ApiConfig.medications}${medication.id}/',
        data: medication.toJson(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMedication(int id) async {
    try {
      final response = await _api.delete('${ApiConfig.medications}$id/');
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // Emergency Contacts
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    try {
      final response = await _api.get(ApiConfig.emergencyContacts);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((c) => EmergencyContact.fromJson(c))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addEmergencyContact(EmergencyContact contact) async {
    try {
      final response =
          await _api.post(ApiConfig.emergencyContacts, data: contact.toJson());
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateEmergencyContact(EmergencyContact contact) async {
    try {
      final response = await _api.put(
        '${ApiConfig.emergencyContacts}${contact.id}/',
        data: contact.toJson(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteEmergencyContact(int id) async {
    try {
      final response = await _api.delete('${ApiConfig.emergencyContacts}$id/');
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
