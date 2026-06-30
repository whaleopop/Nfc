"""
URLs for profiles app
"""
from django.urls import path
from .views import (
    MedicalProfileView,
    AllergyListCreateView,
    AllergyDetailView,
    ChronicDiseaseListCreateView,
    ChronicDiseaseDetailView,
    MedicationListCreateView,
    MedicationDetailView,
    EmergencyContactListCreateView,
    EmergencyContactDetailView,
    DoctorNoteListCreateView,
    DoctorNoteDetailView,
    # Doctor-only views
    PatientListView,
    PatientProfileView,
    PatientAllergyListCreateView,
    PatientAllergyDetailView,
    PatientChronicDiseaseListCreateView,
    PatientChronicDiseaseDetailView,
    PatientMedicationListCreateView,
    PatientMedicationDetailView,
    PatientEmergencyContactListCreateView,
    PatientEmergencyContactDetailView,
)

app_name = 'profiles'

urlpatterns = [
    # Medical Profile (own)
    path('', MedicalProfileView.as_view(), name='profile'),

    # Allergies (own)
    path('allergies/', AllergyListCreateView.as_view(), name='allergy-list'),
    path('allergies/<uuid:pk>/', AllergyDetailView.as_view(), name='allergy-detail'),

    # Chronic Diseases (own)
    path('chronic-diseases/', ChronicDiseaseListCreateView.as_view(), name='chronic-disease-list'),
    path('chronic-diseases/<uuid:pk>/', ChronicDiseaseDetailView.as_view(), name='chronic-disease-detail'),

    # Medications (own)
    path('medications/', MedicationListCreateView.as_view(), name='medication-list'),
    path('medications/<uuid:pk>/', MedicationDetailView.as_view(), name='medication-detail'),

    # Emergency Contacts (own)
    path('emergency-contacts/', EmergencyContactListCreateView.as_view(), name='emergency-contact-list'),
    path('emergency-contacts/<uuid:pk>/', EmergencyContactDetailView.as_view(), name='emergency-contact-detail'),

    # Doctor Notes
    path('doctor-notes/', DoctorNoteListCreateView.as_view(), name='doctor-note-list'),
    path('doctor-notes/<uuid:pk>/', DoctorNoteDetailView.as_view(), name='doctor-note-detail'),

    # Doctor-only: manage any patient's data
    path('patients/', PatientListView.as_view(), name='patient-list'),
    path('patients/<uuid:user_id>/profile/', PatientProfileView.as_view(), name='patient-profile'),
    path('patients/<uuid:user_id>/allergies/', PatientAllergyListCreateView.as_view(), name='patient-allergy-list'),
    path('patients/<uuid:user_id>/allergies/<uuid:pk>/', PatientAllergyDetailView.as_view(), name='patient-allergy-detail'),
    path('patients/<uuid:user_id>/chronic-diseases/', PatientChronicDiseaseListCreateView.as_view(), name='patient-disease-list'),
    path('patients/<uuid:user_id>/chronic-diseases/<uuid:pk>/', PatientChronicDiseaseDetailView.as_view(), name='patient-disease-detail'),
    path('patients/<uuid:user_id>/medications/', PatientMedicationListCreateView.as_view(), name='patient-medication-list'),
    path('patients/<uuid:user_id>/medications/<uuid:pk>/', PatientMedicationDetailView.as_view(), name='patient-medication-detail'),
    path('patients/<uuid:user_id>/emergency-contacts/', PatientEmergencyContactListCreateView.as_view(), name='patient-contact-list'),
    path('patients/<uuid:user_id>/emergency-contacts/<uuid:pk>/', PatientEmergencyContactDetailView.as_view(), name='patient-contact-detail'),
]
