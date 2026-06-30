"""
Serializers for NFC app
"""
from rest_framework import serializers
from .models import NFCTag, NFCAccessLog, NFCEmergencyAccess


class NFCTagSerializer(serializers.ModelSerializer):
    """NFC Tag serializer"""

    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    is_active = serializers.BooleanField(read_only=True)

    class Meta:
        model = NFCTag
        fields = (
            'id', 'user', 'user_name', 'tag_uid', 'tag_type',
            'public_key_id', 'status', 'is_active', 'registered_at',
            'last_scanned_at', 'scan_count', 'revoked_at',
            'revoked_reason', 'created_at', 'updated_at'
        )
        read_only_fields = (
            'id', 'user', 'user_name', 'is_active', 'registered_at',
            'last_scanned_at', 'scan_count', 'revoked_at',
            'created_at', 'updated_at'
        )


class NFCTagRegisterSerializer(serializers.Serializer):
    """NFC Tag registration serializer"""

    tag_uid = serializers.CharField(max_length=255, required=True)
    tag_type = serializers.CharField(max_length=50, default='NTAG215')

    def validate_tag_uid(self, value):
        """Block only if tag is currently ACTIVE; revoked tags can be re-registered"""
        if NFCTag.objects.filter(tag_uid=value, status='ACTIVE').exists():
            raise serializers.ValidationError('Эта метка уже активно зарегистрирована')
        return value


class NFCTagScanSerializer(serializers.Serializer):
    """NFC Tag scan serializer"""

    tag_uid = serializers.CharField(max_length=255, required=True)
    public_key_id = serializers.CharField(max_length=255, required=True)
    checksum = serializers.CharField(max_length=255, required=True)

    # Optional geolocation
    latitude = serializers.DecimalField(
        max_digits=9,
        decimal_places=6,
        required=False,
        allow_null=True
    )
    longitude = serializers.DecimalField(
        max_digits=9,
        decimal_places=6,
        required=False,
        allow_null=True
    )

    def validate(self, attrs):
        """Validate NFC tag data"""
        tag_uid = attrs.get('tag_uid')

        try:
            nfc_tag = NFCTag.objects.get(tag_uid=tag_uid)

            if not nfc_tag.is_active:
                raise serializers.ValidationError({
                    'tag_uid': f'Метка {nfc_tag.get_status_display().lower()}'
                })

            # Verify checksum
            data_to_verify = f"{tag_uid}{attrs.get('public_key_id')}"
            if not nfc_tag.verify_checksum(data_to_verify):
                raise serializers.ValidationError({
                    'checksum': 'Неверная контрольная сумма'
                })

            attrs['nfc_tag'] = nfc_tag

        except NFCTag.DoesNotExist:
            raise serializers.ValidationError({
                'tag_uid': 'Метка не найдена'
            })

        return attrs


class NFCTagRevokeSerializer(serializers.Serializer):
    """NFC Tag revocation serializer"""

    tag_id = serializers.UUIDField(required=True)
    reason = serializers.CharField(required=False, allow_blank=True)


class NFCAccessLogSerializer(serializers.ModelSerializer):
    """NFC Access Log serializer"""

    nfc_tag_uid = serializers.CharField(source='nfc_tag.tag_uid', read_only=True)
    accessed_by_name = serializers.CharField(source='accessed_by.get_full_name', read_only=True)

    class Meta:
        model = NFCAccessLog
        fields = (
            'id', 'nfc_tag', 'nfc_tag_uid', 'accessed_by',
            'accessed_by_name', 'access_type', 'status',
            'ip_address', 'user_agent', 'device_info',
            'latitude', 'longitude', 'error_message', 'accessed_at'
        )
        read_only_fields = '__all__'


class NFCEmergencyAccessSerializer(serializers.ModelSerializer):
    """NFC Emergency Access serializer"""

    nfc_tag_uid = serializers.CharField(source='nfc_tag.tag_uid', read_only=True)
    medical_worker_name = serializers.CharField(source='medical_worker.get_full_name', read_only=True)

    class Meta:
        model = NFCEmergencyAccess
        fields = (
            'id', 'nfc_tag', 'nfc_tag_uid', 'medical_worker',
            'medical_worker_name', 'accessed_at', 'ip_address',
            'device_info', 'latitude', 'longitude',
            'data_accessed', 'access_notes'
        )
        read_only_fields = '__all__'
