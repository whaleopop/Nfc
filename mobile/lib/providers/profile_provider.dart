import 'package:flutter/foundation.dart';
import '../models/medical_profile.dart';
import '../services/profile_service.dart';

/// Profile Provider for medical profile management
class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  MedicalProfile? _profile;
  bool _isLoading = false;
  String? _error;

  MedicalProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load user profile
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _profileService.getProfile();
    } catch (e) {
      _error = 'Failed to load profile';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Save profile
  Future<bool> saveProfile(MedicalProfile profile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final success = await _profileService.saveProfile(profile);

    if (success) {
      _profile = profile;
      _error = null;
    } else {
      _error = 'Failed to save profile';
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Add allergy
  Future<bool> addAllergy(Allergy allergy) async {
    final success = await _profileService.addAllergy(allergy);
    if (success) {
      await loadProfile();
    }
    return success;
  }

  /// Delete allergy
  Future<bool> deleteAllergy(int id) async {
    final success = await _profileService.deleteAllergy(id);
    if (success) {
      await loadProfile();
    }
    return success;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
