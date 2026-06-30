"""
Admin configuration for NFC app
"""
from django.contrib import admin
from .models import NFCTag, NFCAccessLog, NFCEmergencyAccess


@admin.register(NFCTag)
class NFCTagAdmin(admin.ModelAdmin):
    list_display = (
        'tag_uid', 'user', 'status', 'scan_count',
        'last_scanned_at', 'registered_at'
    )
    list_filter = ('status', 'tag_type', 'registered_at')
    search_fields = ('tag_uid', 'user__email', 'user__first_name', 'user__last_name')
    readonly_fields = (
        'registered_at', 'last_scanned_at', 'scan_count',
        'created_at', 'updated_at', 'revoked_at'
    )

    fieldsets = (
        ('Основная информация', {
            'fields': ('user', 'tag_uid', 'tag_type', 'status')
        }),
        ('Безопасность', {
            'fields': ('public_key_id', 'checksum')
        }),
        ('Статистика', {
            'fields': ('scan_count', 'last_scanned_at', 'registered_at')
        }),
        ('Отзыв', {
            'fields': ('revoked_at', 'revoked_reason')
        }),
        ('Служебные поля', {
            'fields': ('created_at', 'updated_at')
        }),
    )

    actions = ['revoke_tags']

    def revoke_tags(self, request, queryset):
        """Revoke selected tags"""
        count = 0
        for tag in queryset:
            if tag.is_active:
                tag.revoke(reason='Revoked by admin')
                count += 1

        self.message_user(request, f'{count} метка(и) отозвана(ы)')

    revoke_tags.short_description = 'Отозвать выбранные метки'


@admin.register(NFCAccessLog)
class NFCAccessLogAdmin(admin.ModelAdmin):
    list_display = (
        'nfc_tag', 'accessed_by', 'access_type',
        'status', 'ip_address', 'accessed_at'
    )
    list_filter = ('access_type', 'status', 'accessed_at')
    search_fields = (
        'nfc_tag__tag_uid', 'accessed_by__email',
        'ip_address', 'error_message'
    )
    readonly_fields = (
        'nfc_tag', 'accessed_by', 'access_type', 'status',
        'ip_address', 'user_agent', 'device_info',
        'latitude', 'longitude', 'error_message', 'accessed_at'
    )

    fieldsets = (
        ('Информация о доступе', {
            'fields': ('nfc_tag', 'accessed_by', 'access_type', 'status')
        }),
        ('Устройство и сеть', {
            'fields': ('ip_address', 'user_agent', 'device_info')
        }),
        ('Геолокация', {
            'fields': ('latitude', 'longitude')
        }),
        ('Ошибка', {
            'fields': ('error_message',)
        }),
        ('Время', {
            'fields': ('accessed_at',)
        }),
    )

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False


@admin.register(NFCEmergencyAccess)
class NFCEmergencyAccessAdmin(admin.ModelAdmin):
    list_display = (
        'nfc_tag', 'medical_worker', 'accessed_at',
        'ip_address'
    )
    list_filter = ('accessed_at',)
    search_fields = (
        'nfc_tag__tag_uid', 'medical_worker__email',
        'ip_address', 'access_notes'
    )
    readonly_fields = (
        'nfc_tag', 'medical_worker', 'accessed_at',
        'ip_address', 'device_info', 'latitude',
        'longitude', 'data_accessed', 'access_notes'
    )

    fieldsets = (
        ('Информация о доступе', {
            'fields': ('nfc_tag', 'medical_worker')
        }),
        ('Устройство и сеть', {
            'fields': ('ip_address', 'device_info')
        }),
        ('Геолокация', {
            'fields': ('latitude', 'longitude')
        }),
        ('Данные', {
            'fields': ('data_accessed', 'access_notes')
        }),
        ('Время', {
            'fields': ('accessed_at',)
        }),
    )

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False
