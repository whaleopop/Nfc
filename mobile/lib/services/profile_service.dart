import '../models/medical_profile.dart';
import '../utils/api_config.dart';
import 'api_service.dart';

/// Profile Service for medical profile management
class ProfileService {
  final ApiService _api = ApiService();

  /// Get current user's profile
  Future<MedicalProfile?> getProfile() async {
    try {
      print('[ProfileService] GET ${ApiConfig.profile}');
      final response = await _api.get(ApiConfig.profile);
      print('[ProfileService] profile status: ${response.statusCode}');
      print('[ProfileService] profile data: ${response.data}');
      if (response.statusCode == 200 && response.data != null) {
        return MedicalProfile.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('[ProfileService] getProfile error: $e');
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

  Future<Allergy?> addAllergy(Allergy allergy) async {
    try {
      final response = await _api.post(ApiConfig.allergies, data: allergy.toJson());
      if (response.statusCode == 201) return Allergy.fromJson(response.data);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Allergy?> updateAllergy(Allergy allergy) async {
    try {
      final response = await _api.put(
        '${ApiConfig.allergies}${allergy.id}/',
        data: allergy.toJson(),
      );
      if (response.statusCode == 200) return Allergy.fromJson(response.data);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteAllergy(String id) async {
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
        return (response.data as List).map((d) => ChronicDisease.fromJson(d)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<ChronicDisease?> addChronicDisease(ChronicDisease disease) async {
    try {
      final response = await _api.post(ApiConfig.chronicDiseases, data: disease.toJson());
      if (response.statusCode == 201) return ChronicDisease.fromJson(response.data);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<ChronicDisease?> updateChronicDisease(ChronicDisease disease) async {
    try {
      final response = await _api.put(
        '${ApiConfig.chronicDiseases}${disease.id}/',
        data: disease.toJson(),
      );
      if (response.statusCode == 200) return ChronicDisease.fromJson(response.data);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteChronicDisease(String id) async {
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
        return (response.data as List).map((m) => Medication.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Medication?> addMedication(Medication medication) async {
    try {
      final response = await _api.post(ApiConfig.medications, data: medication.toJson());
      if (response.statusCode == 201) return Medication.fromJson(response.data);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Medication?> updateMedication(Medication medication) async {
    try {
      final response = await _api.put(
        '${ApiConfig.medications}${medication.id}/',
        data: medication.toJson(),
      );
      if (response.statusCode == 200) return Medication.fromJson(response.data);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteMedication(String id) async {
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
        return (response.data as List).map((c) => EmergencyContact.fromJson(c)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<EmergencyContact?> addEmergencyContact(EmergencyContact contact) async {
    try {
      final response = await _api.post(ApiConfig.emergencyContacts, data: contact.toJson());
      if (response.statusCode == 201) return EmergencyContact.fromJson(response.data);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<EmergencyContact?> updateEmergencyContact(EmergencyContact contact) async {
    try {
      final response = await _api.put(
        '${ApiConfig.emergencyContacts}${contact.id}/',
        data: contact.toJson(),
      );
      if (response.statusCode == 200) return EmergencyContact.fromJson(response.data);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteEmergencyContact(String id) async {
    try {
      final response = await _api.delete('${ApiConfig.emergencyContacts}$id/');
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
