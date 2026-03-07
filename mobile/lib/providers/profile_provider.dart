import 'package:flutter/foundation.dart';
import '../models/medical_profile.dart';
import '../services/profile_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  MedicalProfile? _profile;
  bool _isLoading = false;
  String? _error;

  MedicalProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProfile() async {
    print('[ProfileProvider] loadProfile called');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _profileService.getProfile();
      print('[ProfileProvider] profile loaded: ${_profile?.id}');
    } catch (e) {
      print('[ProfileProvider] loadProfile error: $e');
      _error = 'Failed to load profile';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveProfile(MedicalProfile profile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final success = await _profileService.saveProfile(profile);

    if (success) {
      // Reload to get full profile with nested lists
      _profile = await _profileService.getProfile() ?? profile;
      _error = null;
    } else {
      _error = 'Failed to save profile';
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // ── Allergies ──────────────────────────────────────────────────────────────

  Future<bool> addAllergy(Allergy allergy) async {
    final created = await _profileService.addAllergy(allergy);
    if (created != null && _profile != null) {
      _profile = _copyWith(allergies: [..._profile!.allergies, created]);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateAllergy(Allergy allergy) async {
    final updated = await _profileService.updateAllergy(allergy);
    if (updated != null && _profile != null) {
      _profile = _copyWith(
        allergies: _profile!.allergies
            .map((a) => a.id == updated.id ? updated : a)
            .toList(),
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteAllergy(String id) async {
    final success = await _profileService.deleteAllergy(id);
    if (success && _profile != null) {
      _profile = _copyWith(
        allergies: _profile!.allergies.where((a) => a.id != id).toList(),
      );
      notifyListeners();
    }
    return success;
  }

  // ── Chronic Diseases ───────────────────────────────────────────────────────

  Future<bool> addChronicDisease(ChronicDisease disease) async {
    final created = await _profileService.addChronicDisease(disease);
    if (created != null && _profile != null) {
      _profile = _copyWith(
          chronicDiseases: [..._profile!.chronicDiseases, created]);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateChronicDisease(ChronicDisease disease) async {
    final updated = await _profileService.updateChronicDisease(disease);
    if (updated != null && _profile != null) {
      _profile = _copyWith(
        chronicDiseases: _profile!.chronicDiseases
            .map((d) => d.id == updated.id ? updated : d)
            .toList(),
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteChronicDisease(String id) async {
    final success = await _profileService.deleteChronicDisease(id);
    if (success && _profile != null) {
      _profile = _copyWith(
        chronicDiseases:
            _profile!.chronicDiseases.where((d) => d.id != id).toList(),
      );
      notifyListeners();
    }
    return success;
  }

  // ── Medications ────────────────────────────────────────────────────────────

  Future<bool> addMedication(Medication medication) async {
    final created = await _profileService.addMedication(medication);
    if (created != null && _profile != null) {
      _profile =
          _copyWith(medications: [..._profile!.medications, created]);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateMedication(Medication medication) async {
    final updated = await _profileService.updateMedication(medication);
    if (updated != null && _profile != null) {
      _profile = _copyWith(
        medications: _profile!.medications
            .map((m) => m.id == updated.id ? updated : m)
            .toList(),
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteMedication(String id) async {
    final success = await _profileService.deleteMedication(id);
    if (success && _profile != null) {
      _profile = _copyWith(
        medications: _profile!.medications.where((m) => m.id != id).toList(),
      );
      notifyListeners();
    }
    return success;
  }

  // ── Emergency Contacts ─────────────────────────────────────────────────────

  Future<bool> addEmergencyContact(EmergencyContact contact) async {
    final created = await _profileService.addEmergencyContact(contact);
    if (created != null && _profile != null) {
      _profile = _copyWith(
          emergencyContacts: [..._profile!.emergencyContacts, created]);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateEmergencyContact(EmergencyContact contact) async {
    final updated = await _profileService.updateEmergencyContact(contact);
    if (updated != null && _profile != null) {
      _profile = _copyWith(
        emergencyContacts: _profile!.emergencyContacts
            .map((c) => c.id == updated.id ? updated : c)
            .toList(),
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteEmergencyContact(String id) async {
    final success = await _profileService.deleteEmergencyContact(id);
    if (success && _profile != null) {
      _profile = _copyWith(
        emergencyContacts:
            _profile!.emergencyContacts.where((c) => c.id != id).toList(),
      );
      notifyListeners();
    }
    return success;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  MedicalProfile _copyWith({
    List<Allergy>? allergies,
    List<ChronicDisease>? chronicDiseases,
    List<Medication>? medications,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return MedicalProfile(
      id: _profile!.id,
      bloodType: _profile!.bloodType,
      height: _profile!.height,
      weight: _profile!.weight,
      emergencyNotes: _profile!.emergencyNotes,
      allergies: allergies ?? _profile!.allergies,
      chronicDiseases: chronicDiseases ?? _profile!.chronicDiseases,
      medications: medications ?? _profile!.medications,
      emergencyContacts: emergencyContacts ?? _profile!.emergencyContacts,
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
