"""
Serializers for audit app
"""
from rest_framework import serializers
from .models import AuditLog, SecurityEvent


class AuditLogSerializer(serializers.ModelSerializer):
    """Audit log serializer"""

    user_name = serializers.CharField(source='user.get_full_name', read_only=True)

    class Meta:
        model = AuditLog
        fields = (
            'id', 'user', 'user_name', 'action', 'resource_type',
            'resource_id', 'resource_name', 'description', 'severity',
            'ip_address', 'user_agent', 'endpoint', 'method',
            'old_value', 'new_value', 'success', 'error_message',
            'created_at'
        )
        read_only_fields = '__all__'


class SecurityEventSerializer(serializers.ModelSerializer):
    """Security event serializer"""

    user_name = serializers.CharField(source='user.get_full_name', read_only=True)

    class Meta:
        model = SecurityEvent
        fields = (
            'id', 'event_type', 'severity', 'user', 'user_name',
            'ip_address', 'user_agent', 'endpoint', 'description',
            'additional_data', 'action_taken', 'is_resolved',
            'resolved_at', 'created_at'
        )
        read_only_fields = '__all__'
