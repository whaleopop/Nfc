"""
Admin configuration for audit app
"""
from django.contrib import admin
from .models import AuditLog, SecurityEvent


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = (
        'user', 'action', 'resource_type', 'resource_name',
        'severity', 'success', 'created_at'
    )
    list_filter = ('action', 'resource_type', 'severity', 'success', 'created_at')
    search_fields = (
        'user__email', 'resource_name', 'description',
        'ip_address', 'endpoint'
    )
    readonly_fields = (
        'id', 'user', 'action', 'resource_type', 'resource_id',
        'resource_name', 'description', 'severity', 'ip_address',
        'user_agent', 'endpoint', 'method', 'old_value',
        'new_value', 'success', 'error_message', 'created_at'
    )

    fieldsets = (
        ('Пользователь', {
            'fields': ('user',)
        }),
        ('Действие', {
            'fields': ('action', 'resource_type', 'resource_id', 'resource_name')
        }),
        ('Детали', {
            'fields': ('description', 'severity', 'success', 'error_message')
        }),
        ('Запрос', {
            'fields': ('ip_address', 'user_agent', 'endpoint', 'method')
        }),
        ('Изменения', {
            'fields': ('old_value', 'new_value')
        }),
        ('Время', {
            'fields': ('created_at',)
        }),
    )

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        # Only superusers can delete audit logs
        return request.user.is_superuser


@admin.register(SecurityEvent)
class SecurityEventAdmin(admin.ModelAdmin):
    list_display = (
        'event_type', 'severity', 'user', 'ip_address',
        'is_resolved', 'created_at'
    )
    list_filter = ('event_type', 'severity', 'is_resolved', 'created_at')
    search_fields = (
        'user__email', 'ip_address', 'description',
        'endpoint', 'action_taken'
    )
    readonly_fields = (
        'id', 'event_type', 'severity', 'user', 'ip_address',
        'user_agent', 'endpoint', 'description',
        'additional_data', 'created_at'
    )

    fieldsets = (
        ('Событие', {
            'fields': ('event_type', 'severity')
        }),
        ('Связанные данные', {
            'fields': ('user', 'ip_address', 'user_agent', 'endpoint')
        }),
        ('Детали', {
            'fields': ('description', 'additional_data')
        }),
        ('Действия', {
            'fields': ('action_taken', 'is_resolved', 'resolved_at')
        }),
        ('Время', {
            'fields': ('created_at',)
        }),
    )

    actions = ['mark_resolved']

    def mark_resolved(self, request, queryset):
        """Mark security events as resolved"""
        from django.utils import timezone
        count = queryset.filter(is_resolved=False).update(
            is_resolved=True,
            resolved_at=timezone.now()
        )
        self.message_user(request, f'{count} событие(й) отмечено как решенное')

    mark_resolved.short_description = 'Отметить как решенное'

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        # Only superusers can delete security events
        return request.user.is_superuser
