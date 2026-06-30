"""
Medical profile models for NFC Medical Platform
"""
from django.db import models
from django.conf import settings
import uuid


class MedicalProfile(models.Model):
    """Medical profile for patients"""

    BLOOD_TYPE_CHOICES = (
        ('I+', 'I(0) Rh+'),
        ('I-', 'I(0) Rh-'),
        ('II+', 'II(A) Rh+'),
        ('II-', 'II(A) Rh-'),
        ('III+', 'III(B) Rh+'),
        ('III-', 'III(B) Rh-'),
        ('IV+', 'IV(AB) Rh+'),
        ('IV-', 'IV(AB) Rh-'),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='medical_profile',
        verbose_name='Пользователь'
    )

    # Basic medical info
    blood_type = models.CharField(
        max_length=4,
        choices=BLOOD_TYPE_CHOICES,
        blank=True,
        verbose_name='Группа крови'
    )
    height = models.PositiveIntegerField(blank=True, null=True, verbose_name='Рост (см)')
    weight = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True, verbose_name='Вес (кг)')

    # Emergency info
    emergency_notes = models.TextField(blank=True, verbose_name='Экстренные заметки')

    # Privacy settings
    is_public = models.BooleanField(default=True, verbose_name='Разрешить экстренный доступ')

    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Создан')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Обновлен')

    class Meta:
        db_table = 'medical_profiles'
        verbose_name = 'Медицинский профиль'
        verbose_name_plural = 'Медицинские профили'

    def __str__(self):
        return f"Профиль {self.user.get_full_name()}"


class Allergy(models.Model):
    """Patient allergies"""

    SEVERITY_CHOICES = (
        ('MILD', 'Легкая'),
        ('MODERATE', 'Средняя'),
        ('SEVERE', 'Тяжелая'),
        ('LIFE_THREATENING', 'Опасная для жизни'),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        MedicalProfile,
        on_delete=models.CASCADE,
        related_name='allergies',
        verbose_name='Профиль'
    )

    allergen = models.CharField(max_length=255, verbose_name='Аллерген')
    severity = models.CharField(
        max_length=20,
        choices=SEVERITY_CHOICES,
        default='MODERATE',
        verbose_name='Тяжесть'
    )
    reaction = models.TextField(blank=True, verbose_name='Реакция')
    notes = models.TextField(blank=True, verbose_name='Примечания')

    diagnosed_date = models.DateField(blank=True, null=True, verbose_name='Дата диагностирования')

    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Создана')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Обновлена')

    class Meta:
        db_table = 'allergies'
        verbose_name = 'Аллергия'
        verbose_name_plural = 'Аллергии'

    def __str__(self):
        return f"{self.allergen} - {self.get_severity_display()}"


class ChronicDisease(models.Model):
    """Chronic diseases"""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        MedicalProfile,
        on_delete=models.CASCADE,
        related_name='chronic_diseases',
        verbose_name='Профиль'
    )

    disease_name = models.CharField(max_length=255, verbose_name='Название заболевания')
    icd_code = models.CharField(max_length=10, blank=True, verbose_name='Код МКБ-10')
    diagnosis_date = models.DateField(blank=True, null=True, verbose_name='Дата диагностирования')
    notes = models.TextField(blank=True, verbose_name='Примечания')

    is_active = models.BooleanField(default=True, verbose_name='Активно')

    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Создано')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Обновлено')

    class Meta:
        db_table = 'chronic_diseases'
        verbose_name = 'Хроническое заболевание'
        verbose_name_plural = 'Хронические заболевания'

    def __str__(self):
        return self.disease_name


class Medication(models.Model):
    """Current medications"""

    FREQUENCY_CHOICES = (
        ('ONCE_DAILY', '1 раз в день'),
        ('TWICE_DAILY', '2 раза в день'),
        ('THREE_TIMES_DAILY', '3 раза в день'),
        ('FOUR_TIMES_DAILY', '4 раза в день'),
        ('AS_NEEDED', 'По необходимости'),
        ('WEEKLY', 'Еженедельно'),
        ('MONTHLY', 'Ежемесячно'),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        MedicalProfile,
        on_delete=models.CASCADE,
        related_name='medications',
        verbose_name='Профиль'
    )

    medication_name = models.CharField(max_length=255, verbose_name='Название препарата')
    dosage = models.CharField(max_length=100, verbose_name='Дозировка')
    frequency = models.CharField(
        max_length=20,
        choices=FREQUENCY_CHOICES,
        verbose_name='Частота приема'
    )

    start_date = models.DateField(verbose_name='Дата начала приема')
    end_date = models.DateField(blank=True, null=True, verbose_name='Дата окончания приема')

    prescribing_doctor = models.CharField(max_length=255, blank=True, verbose_name='Назначивший врач')
    notes = models.TextField(blank=True, verbose_name='Примечания')

    is_active = models.BooleanField(default=True, verbose_name='Активно')

    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Создано')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Обновлено')

    class Meta:
        db_table = 'medications'
        verbose_name = 'Медикамент'
        verbose_name_plural = 'Медикаменты'

    def __str__(self):
        return f"{self.medication_name} ({self.dosage})"


class EmergencyContact(models.Model):
    """Emergency contacts"""

    RELATIONSHIP_CHOICES = (
        ('SPOUSE', 'Супруг/Супруга'),
        ('PARENT', 'Родитель'),
        ('CHILD', 'Ребенок'),
        ('SIBLING', 'Брат/Сестра'),
        ('FRIEND', 'Друг'),
        ('OTHER', 'Другое'),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        MedicalProfile,
        on_delete=models.CASCADE,
        related_name='emergency_contacts',
        verbose_name='Профиль'
    )

    full_name = models.CharField(max_length=255, verbose_name='ФИО')
    relationship = models.CharField(
        max_length=20,
        choices=RELATIONSHIP_CHOICES,
        verbose_name='Отношение'
    )

    phone = models.CharField(max_length=20, verbose_name='Телефон')
    email = models.EmailField(blank=True, verbose_name='Email')

    priority = models.PositiveSmallIntegerField(default=1, verbose_name='Приоритет')

    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Создан')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Обновлен')

    class Meta:
        db_table = 'emergency_contacts'
        verbose_name = 'Экстренный контакт'
        verbose_name_plural = 'Экстренные контакты'
        ordering = ['priority']

    def __str__(self):
        return f"{self.full_name} ({self.get_relationship_display()})"


class DoctorNote(models.Model):
    """Doctor notes for patients"""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        MedicalProfile,
        on_delete=models.CASCADE,
        related_name='doctor_notes',
        verbose_name='Профиль'
    )
    doctor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_notes',
        verbose_name='Врач'
    )

    note = models.TextField(verbose_name='Заметка')
    is_emergency_visible = models.BooleanField(
        default=False,
        verbose_name='Видимо при экстренном доступе'
    )

    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Создана')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Обновлена')

    class Meta:
        db_table = 'doctor_notes'
        verbose_name = 'Заметка врача'
        verbose_name_plural = 'Заметки врачей'
        ordering = ['-created_at']

    def __str__(self):
        return f"Заметка от {self.doctor.get_full_name() if self.doctor else 'Unknown'}"
