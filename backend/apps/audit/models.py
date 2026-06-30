"""
Audit models for NFC Medical Platform
"""
from django.db import models
from django.conf import settings
import uuid


class AuditLog(models.Model):
    """Audit log for all system actions"""

    ACTION_CHOICES = (
        ('CREATE', 'Создание'),
        ('UPDATE', 'Обновление'),
        ('DELETE', 'Удаление'),
        ('READ', 'Чтение'),
        ('LOGIN', 'Вход'),
        ('LOGOUT', 'Выход'),
        ('REGISTER', 'Регистрация'),
        ('PASSWORD_CHANGE', 'Смена пароля'),
        ('2FA_ENABLE', '2FA включен'),
        ('2FA_DISABLE', '2FA отключен'),
        ('NFC_REGISTER', 'Регистрация NFC метки'),
        ('NFC_SCAN', 'Сканирование NFC метки'),
        ('NFC_REVOKE', 'Отзыв NFC метки'),
        ('EMERGENCY_ACCESS', 'Экстренный доступ'),
        ('OTHER', 'Другое'),
    )

    RESOURCE_CHOICES = (
        ('USER', 'Пользователь'),
        ('PROFILE', 'Профиль'),
        ('ALLERGY', 'Аллергия'),
        ('DISEASE', 'Заболевание'),
        ('MEDICATION', 'Медикамент'),
        ('CONTACT', 'Контакт'),
        ('NOTE', 'Заметка'),
        ('NFC_TAG', 'NFC метка'),
        ('SYSTEM', 'Система'),
    )

    SEVERITY_CHOICES = (
        ('LOW', 'Низкий'),
        ('MEDIUM', 'Средний'),
        ('HIGH', 'Высокий'),
        ('CRITICAL', 'Критический'),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Who performed the action
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_logs',
        verbose_name='Пользователь'
    )

    # Action details
    action = models.CharField(max_length=50, choices=ACTION_CHOICES, verbose_name='Действие')
    resource_type = models.CharField(
        max_length=50,
        choices=RESOURCE_CHOICES,
        verbose_name='Тип ресурса'
    )
    resource_id = models.CharField(max_length=255, blank=True, verbose_name='ID ресурса')
    resource_name = models.CharField(max_length=255, blank=True, verbose_name='Название ресурса')

    # Additional info
    description = models.TextField(blank=True, verbose_name='Описание')
    severity = models.CharField(
        max_length=20,
        choices=SEVERITY_CHOICES,
        default='LOW',
        verbose_name='Важность'
    )

    # Request metadata
    ip_address = models.GenericIPAddressField(blank=True, null=True, verbose_name='IP адрес')
    user_agent = models.CharField(max_length=500, blank=True, verbose_name='User Agent')
    endpoint = models.CharField(max_length=255, blank=True, verbose_name='API Endpoint')
    method = models.CharField(max_length=10, blank=True, verbose_name='HTTP метод')

    # Changes (JSON)
    old_value = models.JSONField(blank=True, null=True, verbose_name='Старое значение')
    new_value = models.JSONField(blank=True, null=True, verbose_name='Новое значение')

    # Status
    success = models.BooleanField(default=True, verbose_name='Успешно')
    error_message = models.TextField(blank=True, verbose_name='Сообщение об ошибке')

    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Создан', db_index=True)

    class Meta:
        db_table = 'audit_logs'
        verbose_name = 'Лог аудита'
        verbose_name_plural = 'Логи аудита'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['action', '-created_at']),
            models.Index(fields=['resource_type', '-created_at']),
            models.Index(fields=['severity', '-created_at']),
            models.Index(fields=['success', '-created_at']),
        ]

    def __str__(self):
        user_name = self.user.get_full_name() if self.user else 'Anonymous'
        return f"{user_name} - {self.get_action_display()} - {self.created_at}"


class SecurityEvent(models.Model):
    """Security events (failed logins, suspicious activities, etc.)"""

    EVENT_TYPE_CHOICES = (
        ('FAILED_LOGIN', 'Неудачный вход'),
        ('MULTIPLE_FAILED_LOGINS', 'Множественные неудачные входы'),
        ('SUSPICIOUS_IP', 'Подозрительный IP'),
        ('RATE_LIMIT_EXCEEDED', 'Превышен лимит запросов'),
        ('INVALID_TOKEN', 'Невалидный токен'),
        ('UNAUTHORIZED_ACCESS', 'Несанкционированный доступ'),
        ('BRUTE_FORCE_ATTEMPT', 'Попытка брутфорса'),
        ('SQL_INJECTION_ATTEMPT', 'Попытка SQL инъекции'),
        ('XSS_ATTEMPT', 'Попытка XSS атаки'),
        ('OTHER', 'Другое'),
    )

    SEVERITY_CHOICES = (
        ('INFO', 'Информация'),
        ('WARNING', 'Предупреждение'),
        ('DANGER', 'Опасность'),
        ('CRITICAL', 'Критическое'),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    event_type = models.CharField(
        max_length=50,
        choices=EVENT_TYPE_CHOICES,
        verbose_name='Тип события'
    )
    severity = models.CharField(
        max_length=20,
        choices=SEVERITY_CHOICES,
        default='WARNING',
        verbose_name='Важность'
    )

    # Related user (if applicable)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='security_events',
        verbose_name='Пользователь'
    )

    # Request info
    ip_address = models.GenericIPAddressField(verbose_name='IP адрес')
    user_agent = models.CharField(max_length=500, blank=True, verbose_name='User Agent')
    endpoint = models.CharField(max_length=255, blank=True, verbose_name='Endpoint')

    # Event details
    description = models.TextField(verbose_name='Описание')
    additional_data = models.JSONField(blank=True, null=True, verbose_name='Дополнительные данные')

    # Action taken
    action_taken = models.TextField(blank=True, verbose_name='Принятые меры')
    is_resolved = models.BooleanField(default=False, verbose_name='Решено')
    resolved_at = models.DateTimeField(blank=True, null=True, verbose_name='Время решения')

    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Создано', db_index=True)

    class Meta:
        db_table = 'security_events'
        verbose_name = 'Событие безопасности'
        verbose_name_plural = 'События безопасности'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['event_type', '-created_at']),
            models.Index(fields=['severity', '-created_at']),
            models.Index(fields=['ip_address', '-created_at']),
            models.Index(fields=['is_resolved', '-created_at']),
        ]

    def __str__(self):
        return f"{self.get_event_type_display()} - {self.created_at}"
