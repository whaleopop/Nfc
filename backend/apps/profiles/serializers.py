"""
Serializers for profiles app
"""
from rest_framework import serializers
from .models import (
    MedicalProfile,
    Allergy,
    ChronicDisease,
    Medication,
    EmergencyContact,
    DoctorNote
)


class AllergySerializer(serializers.ModelSerializer):
    """Allergy serializer"""

    class Meta:
        model = Allergy
        fields = (
            'id', 'allergen', 'severity', 'reaction', 'notes',
            'diagnosed_date', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')


class ChronicDiseaseSerializer(serializers.ModelSerializer):
    """Chronic disease serializer"""

    class Meta:
        model = ChronicDisease
        fields = (
            'id', 'disease_name', 'icd_code', 'diagnosis_date',
            'notes', 'is_active', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')


class MedicationSerializer(serializers.ModelSerializer):
    """Medication serializer"""

    class Meta:
        model = Medication
        fields = (
            'id', 'medication_name', 'dosage', 'frequency',
            'start_date', 'end_date', 'prescribing_doctor',
            'notes', 'is_active', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')


class EmergencyContactSerializer(serializers.ModelSerializer):
    """Emergency contact serializer"""

    class Meta:
        model = EmergencyContact
        fields = (
            'id', 'full_name', 'relationship', 'phone',
            'email', 'priority', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')


class DoctorNoteSerializer(serializers.ModelSerializer):
    """Doctor note serializer"""

    doctor_name = serializers.CharField(source='doctor.get_full_name', read_only=True)

    class Meta:
        model = DoctorNote
        fields = (
            'id', 'note', 'doctor', 'doctor_name',
            'is_emergency_visible', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'doctor', 'doctor_name', 'created_at', 'updated_at')


class MedicalProfileSerializer(serializers.ModelSerializer):
    """Medical profile serializer (full)"""

    allergies = AllergySerializer(many=True, read_only=True)
    chronic_diseases = ChronicDiseaseSerializer(many=True, read_only=True)
    medications = MedicationSerializer(many=True, read_only=True)
    emergency_contacts = EmergencyContactSerializer(many=True, read_only=True)
    doctor_notes = DoctorNoteSerializer(many=True, read_only=True)

    user_name = serializers.CharField(source='user.get_full_name', read_only=True)

    class Meta:
        model = MedicalProfile
        fields = (
            'id', 'user', 'user_name', 'blood_type', 'height', 'weight',
            'emergency_notes', 'is_public',
            'allergies', 'chronic_diseases', 'medications',
            'emergency_contacts', 'doctor_notes',
            'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'user', 'user_name', 'created_at', 'updated_at')


class EmergencyProfileSerializer(serializers.ModelSerializer):
    """Emergency profile serializer (limited data for emergency access)"""

    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    allergies = AllergySerializer(many=True, read_only=True)
    chronic_diseases = ChronicDiseaseSerializer(many=True, read_only=True)
    medications = MedicationSerializer(many=True, read_only=True)
    emergency_contacts = EmergencyContactSerializer(many=True, read_only=True)
    emergency_notes_visible = serializers.SerializerMethodField()

    class Meta:
        model = MedicalProfile
        fields = (
            'id', 'user_name', 'blood_type',
            'allergies', 'chronic_diseases', 'medications',
            'emergency_contacts', 'emergency_notes_visible'
        )

    def get_emergency_notes_visible(self, obj):
        """Get only emergency-visible doctor notes"""
        notes = obj.doctor_notes.filter(is_emergency_visible=True)
        return DoctorNoteSerializer(notes, many=True).data


class MedicalProfileCreateSerializer(serializers.ModelSerializer):
    """Medical profile create serializer"""

    class Meta:
        model = MedicalProfile
        fields = (
            'blood_type', 'height', 'weight', 'emergency_notes', 'is_public'
        )

    def create(self, validated_data):
        user = self.context['request'].user
        validated_data['user'] = user
        return super().create(validated_data)
