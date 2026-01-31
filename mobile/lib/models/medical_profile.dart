/// Medical Profile model matching Django backend
class MedicalProfile {
  final int? id;
  final String? bloodType;
  final double? height;
  final double? weight;
  final List<Allergy> allergies;
  final List<ChronicDisease> chronicDiseases;
  final List<Medication> medications;
  final List<EmergencyContact> emergencyContacts;

  MedicalProfile({
    this.id,
    this.bloodType,
    this.height,
    this.weight,
    this.allergies = const [],
    this.chronicDiseases = const [],
    this.medications = const [],
    this.emergencyContacts = const [],
  });

  factory MedicalProfile.fromJson(Map<String, dynamic> json) {
    return MedicalProfile(
      id: json['id'],
      bloodType: json['blood_type'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      allergies: (json['allergies'] as List?)
              ?.map((a) => Allergy.fromJson(a))
              .toList() ??
          [],
      chronicDiseases: (json['chronic_diseases'] as List?)
              ?.map((d) => ChronicDisease.fromJson(d))
              .toList() ??
          [],
      medications: (json['medications'] as List?)
              ?.map((m) => Medication.fromJson(m))
              .toList() ??
          [],
      emergencyContacts: (json['emergency_contacts'] as List?)
              ?.map((c) => EmergencyContact.fromJson(c))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'blood_type': bloodType,
      'height': height,
      'weight': weight,
    };
  }
}

/// Allergy model
class Allergy {
  final int? id;
  final String allergen;
  final String severity;
  final String? reaction;
  final String? notes;
  final DateTime? diagnosedDate;

  Allergy({
    this.id,
    required this.allergen,
    required this.severity,
    this.reaction,
    this.notes,
    this.diagnosedDate,
  });

  factory Allergy.fromJson(Map<String, dynamic> json) {
    return Allergy(
      id: json['id'],
      allergen: json['allergen'],
      severity: json['severity'],
      reaction: json['reaction'],
      notes: json['notes'],
      diagnosedDate: json['diagnosed_date'] != null
          ? DateTime.parse(json['diagnosed_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'allergen': allergen,
      'severity': severity,
      if (reaction != null) 'reaction': reaction,
      if (notes != null) 'notes': notes,
      if (diagnosedDate != null)
        'diagnosed_date': diagnosedDate!.toIso8601String().split('T')[0],
    };
  }
}

/// Chronic Disease model
class ChronicDisease {
  final int? id;
  final String diseaseName;
  final String? icdCode;
  final DateTime? diagnosisDate;
  final String? notes;
  final bool isActive;

  ChronicDisease({
    this.id,
    required this.diseaseName,
    this.icdCode,
    this.diagnosisDate,
    this.notes,
    this.isActive = true,
  });

  factory ChronicDisease.fromJson(Map<String, dynamic> json) {
    return ChronicDisease(
      id: json['id'],
      diseaseName: json['disease_name'],
      icdCode: json['icd_code'],
      diagnosisDate: json['diagnosis_date'] != null
          ? DateTime.parse(json['diagnosis_date'])
          : null,
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'disease_name': diseaseName,
      if (icdCode != null) 'icd_code': icdCode,
      if (diagnosisDate != null)
        'diagnosis_date': diagnosisDate!.toIso8601String().split('T')[0],
      if (notes != null) 'notes': notes,
      'is_active': isActive,
    };
  }
}

/// Medication model
class Medication {
  final int? id;
  final String medicationName;
  final String? dosage;
  final String? frequency;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? prescribingDoctor;
  final bool isActive;

  Medication({
    this.id,
    required this.medicationName,
    this.dosage,
    this.frequency,
    this.startDate,
    this.endDate,
    this.prescribingDoctor,
    this.isActive = true,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      medicationName: json['medication_name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      prescribingDoctor: json['prescribing_doctor'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'medication_name': medicationName,
      if (dosage != null) 'dosage': dosage,
      if (frequency != null) 'frequency': frequency,
      if (startDate != null)
        'start_date': startDate!.toIso8601String().split('T')[0],
      if (endDate != null) 'end_date': endDate!.toIso8601String().split('T')[0],
      if (prescribingDoctor != null) 'prescribing_doctor': prescribingDoctor,
      'is_active': isActive,
    };
  }
}

/// Emergency Contact model
class EmergencyContact {
  final int? id;
  final String name;
  final String relationship;
  final String phone;
  final int priority;

  EmergencyContact({
    this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    this.priority = 1,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      relationship: json['relationship'],
      phone: json['phone'],
      priority: json['priority'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'priority': priority,
    };
  }
}

/// Blood type constants (Russian format)
class BloodType {
  static const List<String> values = [
    'I+',
    'I-',
    'II+',
    'II-',
    'III+',
    'III-',
    'IV+',
    'IV-',
  ];

  static String getDisplayName(String bloodType) {
    switch (bloodType) {
      case 'I+':
        return 'I (0) Rh+';
      case 'I-':
        return 'I (0) Rh-';
      case 'II+':
        return 'II (A) Rh+';
      case 'II-':
        return 'II (A) Rh-';
      case 'III+':
        return 'III (B) Rh+';
      case 'III-':
        return 'III (B) Rh-';
      case 'IV+':
        return 'IV (AB) Rh+';
      case 'IV-':
        return 'IV (AB) Rh-';
      default:
        return bloodType;
    }
  }
}

/// Allergy severity levels
class AllergySeverity {
  static const String mild = 'MILD';
  static const String moderate = 'MODERATE';
  static const String severe = 'SEVERE';
  static const String lifeThreatening = 'LIFE_THREATENING';

  static const List<String> values = [
    mild,
    moderate,
    severe,
    lifeThreatening,
  ];

  static String getDisplayName(String severity) {
    switch (severity) {
      case mild:
        return 'Mild';
      case moderate:
        return 'Moderate';
      case severe:
        return 'Severe';
      case lifeThreatening:
        return 'Life Threatening';
      default:
        return severity;
    }
  }
}
