"""
Admin configuration for profiles app
"""
from django.contrib import admin
from .models import (
    MedicalProfile,
    Allergy,
    ChronicDisease,
    Medication,
    EmergencyContact,
    DoctorNote
)


class AllergyInline(admin.TabularInline):
    model = Allergy
    extra = 0


class ChronicDiseaseInline(admin.TabularInline):
    model = ChronicDisease
    extra = 0


class MedicationInline(admin.TabularInline):
    model = Medication
    extra = 0


class EmergencyContactInline(admin.TabularInline):
    model = EmergencyContact
    extra = 0


class DoctorNoteInline(admin.StackedInline):
    model = DoctorNote
    extra = 0


@admin.register(MedicalProfile)
class MedicalProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'blood_type', 'is_public', 'updated_at')
    list_filter = ('blood_type', 'is_public', 'created_at')
    search_fields = ('user__email', 'user__first_name', 'user__last_name')
    readonly_fields = ('created_at', 'updated_at')

    inlines = [
        AllergyInline,
        ChronicDiseaseInline,
        MedicationInline,
        EmergencyContactInline,
        DoctorNoteInline
    ]

    fieldsets = (
        ('Пользователь', {
            'fields': ('user',)
        }),
        ('Основная информация', {
            'fields': ('blood_type', 'height', 'weight')
        }),
        ('Экстренная информация', {
            'fields': ('emergency_notes', 'is_public')
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at')
        }),
    )


@admin.register(Allergy)
class AllergyAdmin(admin.ModelAdmin):
    list_display = ('allergen', 'profile', 'severity', 'diagnosed_date')
    list_filter = ('severity', 'diagnosed_date')
    search_fields = ('allergen', 'profile__user__email')


@admin.register(ChronicDisease)
class ChronicDiseaseAdmin(admin.ModelAdmin):
    list_display = ('disease_name', 'profile', 'icd_code', 'is_active', 'diagnosis_date')
    list_filter = ('is_active', 'diagnosis_date')
    search_fields = ('disease_name', 'icd_code', 'profile__user__email')


@admin.register(Medication)
class MedicationAdmin(admin.ModelAdmin):
    list_display = ('medication_name', 'profile', 'dosage', 'frequency', 'is_active')
    list_filter = ('frequency', 'is_active', 'start_date')
    search_fields = ('medication_name', 'profile__user__email')


@admin.register(EmergencyContact)
class EmergencyContactAdmin(admin.ModelAdmin):
    list_display = ('full_name', 'profile', 'relationship', 'phone', 'priority')
    list_filter = ('relationship', 'priority')
    search_fields = ('full_name', 'phone', 'profile__user__email')


@admin.register(DoctorNote)
class DoctorNoteAdmin(admin.ModelAdmin):
    list_display = ('profile', 'doctor', 'is_emergency_visible', 'created_at')
    list_filter = ('is_emergency_visible', 'created_at')
    search_fields = ('profile__user__email', 'doctor__email', 'note')
    readonly_fields = ('created_at', 'updated_at')
