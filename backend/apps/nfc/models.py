"""
NFC models for NFC Medical Platform
"""
from django.db import models
from django.conf import settings
from django.utils import timezone
import uuid
import hashlib
import hmac


class NFCTag(models.Model):
    """NFC Tag model"""

    STATUS_CHOICES = (
        ('ACTIVE', 'Активна'),
        ('REVOKED', 'Отозвана'),
        ('LOST', 'Утеряна'),
        ('REPLACED', 'Заменена'),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='nfc_tags',
        verbose_name='Пользователь'
    )

    # NFC Tag Info
    tag_uid = models.CharField(max_length=255, unique=True, verbose_name='UID метки')
    tag_type = models.CharField(max_length=50, default='NTAG215', verbose_name='Тип метки')

    # Security
    public_key_id = models.CharField(max_length=255, unique=True, verbose_name='ID публичного ключа')
    checksum = models.CharField(max_length=255, verbose_name='Контрольная сумма')

    # Status
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='ACTIVE',
        verbose_name='Статус'
    )

    # Metadata
    registered_at = models.DateTimeField(auto_now_add=True, verbose_name='Дата регистрации')
    last_scanned_at = models.DateTimeField(blank=True, null=True, verbose_name='Последнее сканирование')
    scan_count = models.PositiveIntegerField(default=0, verbose_name='Количество сканирований')

    # Revocation
    revoked_at = models.DateTimeField(blank=True, null=True, verbose_name='Дата отзыва')
    revoked_reason = models.TextField(blank=True, verbose_name='Причина отзыва')

    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Создана')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Обновлена')

    class Meta:
        db_table = 'nfc_tags'
        verbose_name = 'NFC Метка'
        verbose_name_plural = 'NFC Метки'
        ordering = ['-registered_at']

    def __str__(self):
        return f"NFC Tag {self.tag_uid} - {self.user.get_full_name()}"

    @property
    def is_active(self):
        return self.status == 'ACTIVE'

    def verify_checksum(self, data):
        """Verify checksum using HMAC"""
        secret = settings.NFC_ENCRYPTION_KEY.encode()
        expected_checksum = hmac.new(secret, data.encode(), hashlib.sha256).hexdigest()
        return hmac.compare_digest(expected_checksum, self.checksum)

    def generate_checksum(self, data):
        """Generate checksum using HMAC"""
        secret = settings.NFC_ENCRYPTION_KEY.encode()
        return hmac.new(secret, data.encode(), hashlib.sha256).hexdigest()

    def revoke(self, reason=''):
        """Revoke the NFC tag"""
        self.status = 'REVOKED'
        self.revoked_at = timezone.now()
        self.revoked_reason = reason
        self.save()


class NFCAccessLog(models.Model):
    """Log of NFC tag access attempts"""

    ACCESS_TYPE_CHOICES = (
        ('SCAN', 'Сканирование'),
        ('REGISTER', 'Регистрация'),
        ('REVOKE', 'Отзыв'),
    )

    STATUS_CHOICES = (
        ('SUCCESS', 'Успешно'),
        ('FAILED', 'Неудачно'),
        ('DENIED', 'Отклонено'),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nfc_tag = models.ForeignKey(
        NFCTag,
        on_delete=models.SET_NULL,
        null=True,
        related_name='access_logs',
        verbose_name='NFC Метка'
    )
    accessed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='nfc_accesses',
        verbose_name='Доступ получил'
    )

    access_type = models.CharField(
        max_length=20,
        choices=ACCESS_TYPE_CHOICES,
        verbose_name='Тип доступа'
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        verbose_name='Статус'
    )

    # Request info
    ip_address = models.GenericIPAddressField(verbose_name='IP адрес')
    user_agent = models.CharField(max_length=500, blank=True, verbose_name='User Agent')
    device_info = models.CharField(max_length=255, blank=True, verbose_name='Информация об устройстве')

    # Location (optional)
    latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        blank=True,
        null=True,
        verbose_name='Широта'
    )
    longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        blank=True,
        null=True,
        verbose_name='Долгота'
    )

    # Error info
    error_message = models.TextField(blank=True, verbose_name='Сообщение об ошибке')

    accessed_at = models.DateTimeField(auto_now_add=True, verbose_name='Время доступа')

    class Meta:
        db_table = 'nfc_access_logs'
        verbose_name = 'Лог доступа к NFC'
        verbose_name_plural = 'Логи доступа к NFC'
        ordering = ['-accessed_at']
        indexes = [
            models.Index(fields=['nfc_tag', '-accessed_at']),
            models.Index(fields=['accessed_by', '-accessed_at']),
            models.Index(fields=['ip_address', '-accessed_at']),
        ]

    def __str__(self):
        return f"{self.get_access_type_display()} - {self.get_status_display()} at {self.accessed_at}"


class NFCEmergencyAccess(models.Model):
    """Emergency access to medical profile via NFC"""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nfc_tag = models.ForeignKey(
        NFCTag,
        on_delete=models.CASCADE,
        related_name='emergency_accesses',
        verbose_name='NFC Метка'
    )
    medical_worker = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='emergency_accesses',
        verbose_name='Медработник'
    )

    # Access details
    accessed_at = models.DateTimeField(auto_now_add=True, verbose_name='Время доступа')
    ip_address = models.GenericIPAddressField(verbose_name='IP адрес')
    device_info = models.CharField(max_length=255, blank=True, verbose_name='Информация об устройстве')

    # Location
    latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        blank=True,
        null=True,
        verbose_name='Широта'
    )
    longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        blank=True,
        null=True,
        verbose_name='Долгота'
    )

    # Accessed data snapshot (JSON)
    data_accessed = models.JSONField(default=dict, verbose_name='Данные, к которым получен доступ')

    # Notes
    access_notes = models.TextField(blank=True, verbose_name='Заметки о доступе')

    class Meta:
        db_table = 'nfc_emergency_accesses'
        verbose_name = 'Экстренный доступ через NFC'
        verbose_name_plural = 'Экстренные доступы через NFC'
        ordering = ['-accessed_at']

    def __str__(self):
        worker_name = self.medical_worker.get_full_name() if self.medical_worker else 'Unknown'
        return f"Emergency access by {worker_name} at {self.accessed_at}"
