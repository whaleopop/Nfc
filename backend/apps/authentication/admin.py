"""
Admin configuration for authentication app
"""
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _
from .models import User, RefreshToken


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Custom User admin"""

    list_display = ('email', 'get_full_name', 'role', 'is_active', 'is_verified', 'date_joined')
    list_filter = ('role', 'is_active', 'is_verified', 'two_factor_enabled', 'date_joined')
    search_fields = ('email', 'first_name', 'last_name', 'phone')
    ordering = ('-date_joined',)

    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        (_('Персональная информация'), {'fields': ('first_name', 'last_name', 'middle_name', 'phone')}),
        (_('Права доступа'), {'fields': ('role', 'is_active', 'is_staff', 'is_superuser', 'is_verified')}),
        (_('Безопасность'), {'fields': ('two_factor_enabled',)}),
        (_('Важные даты'), {'fields': ('last_login', 'date_joined')}),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'password1', 'password2', 'first_name', 'last_name', 'role'),
        }),
    )

    readonly_fields = ('date_joined', 'last_login')


@admin.register(RefreshToken)
class RefreshTokenAdmin(admin.ModelAdmin):
    """RefreshToken admin"""

    list_display = ('user', 'is_active', 'created_at', 'expires_at', 'ip_address')
    list_filter = ('is_active', 'created_at', 'expires_at')
    search_fields = ('user__email', 'ip_address', 'device_info')
    readonly_fields = ('user', 'token', 'created_at', 'expires_at', 'device_info', 'ip_address')

    def has_add_permission(self, request):
        return False
