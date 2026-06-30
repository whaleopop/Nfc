"""
Views for NFC app
"""
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.utils import timezone
from django.shortcuts import get_object_or_404
import uuid

from .models import NFCTag, NFCAccessLog, NFCEmergencyAccess
from .serializers import (
    NFCTagSerializer,
    NFCTagRegisterSerializer,
    NFCTagScanSerializer,
    NFCTagRevokeSerializer,
    NFCAccessLogSerializer,
    NFCEmergencyAccessSerializer
)
from apps.profiles.serializers import EmergencyProfileSerializer
from apps.profiles.models import MedicalProfile


class NFCTagListView(generics.ListAPIView):
    """List user's NFC tags"""

    serializer_class = NFCTagSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None  # Disable pagination for personal data

    def get_queryset(self):
        return NFCTag.objects.filter(user=self.request.user).order_by('-registered_at')


class NFCTagRegisterView(APIView):
    """Register a new NFC tag"""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = NFCTagRegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Check if user has medical profile
        if not hasattr(request.user, 'medical_profile'):
            return Response(
                {'error': 'Сначала создайте медицинский профиль'},
                status=status.HTTP_400_BAD_REQUEST
            )

        tag_uid = serializer.validated_data['tag_uid']
        tag_type = serializer.validated_data['tag_type']

        # Reactivate existing revoked tag (same physical tag, same user)
        existing = NFCTag.objects.filter(tag_uid=tag_uid, user=request.user).first()
        if existing:
            existing.status = 'ACTIVE'
            existing.revoked_at = None
            existing.revoked_reason = ''
            existing.save(update_fields=['status', 'revoked_at', 'revoked_reason'])
            nfc_tag = existing
        else:
            # Check if tag belongs to another user
            if NFCTag.objects.filter(tag_uid=tag_uid).exists():
                return Response(
                    {'error': 'Эта метка зарегистрирована другим пользователем'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            # Create new NFC tag
            public_key_id = str(uuid.uuid4())
            nfc_tag = NFCTag.objects.create(
                user=request.user,
                tag_uid=tag_uid,
                tag_type=tag_type,
                public_key_id=public_key_id,
            )
            data = f"{tag_uid}{public_key_id}"
            nfc_tag.checksum = nfc_tag.generate_checksum(data)
            nfc_tag.save()

        # Log registration
        self._log_access(
            nfc_tag=nfc_tag,
            access_type='REGISTER',
            status='SUCCESS',
            request=request
        )

        return Response({
            'tag': NFCTagSerializer(nfc_tag).data,
            'nfc_data': {
                'tag_id': str(nfc_tag.id),
                'public_key_id': nfc_tag.public_key_id,
                'checksum': nfc_tag.checksum
            },
            'message': 'NFC метка успешно зарегистрирована'
        }, status=status.HTTP_201_CREATED)

    def _log_access(self, nfc_tag, access_type, status, request, error_message=''):
        """Helper to log access"""
        NFCAccessLog.objects.create(
            nfc_tag=nfc_tag,
            accessed_by=request.user if request.user.is_authenticated else None,
            access_type=access_type,
            status=status,
            ip_address=self._get_client_ip(request),
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            error_message=error_message
        )

    def _get_client_ip(self, request):
        """Get client IP address"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR', '127.0.0.1')
        return ip


class NFCTagScanView(APIView):
    """Scan NFC tag and get emergency medical data"""

    permission_classes = [permissions.AllowAny]  # Emergency access doesn't require auth

    def post(self, request):
        serializer = NFCTagScanSerializer(data=request.data)

        try:
            serializer.is_valid(raise_exception=True)
        except Exception as e:
            # Log failed scan
            self._log_failed_scan(request, str(e))
            raise

        nfc_tag = serializer.validated_data['nfc_tag']

        # Update scan statistics
        nfc_tag.last_scanned_at = timezone.now()
        nfc_tag.scan_count += 1
        nfc_tag.save(update_fields=['last_scanned_at', 'scan_count'])

        # Get medical profile
        try:
            profile = nfc_tag.user.medical_profile

            if not profile.is_public:
                self._log_access(
                    nfc_tag=nfc_tag,
                    access_type='SCAN',
                    status='DENIED',
                    request=request,
                    error_message='Profile is private'
                )
                return Response(
                    {'error': 'Пользователь отключил экстренный доступ'},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Serialize emergency profile data
            profile_data = EmergencyProfileSerializer(profile).data

            # Log successful access
            self._log_access(
                nfc_tag=nfc_tag,
                access_type='SCAN',
                status='SUCCESS',
                request=request
            )

            # Create emergency access record
            NFCEmergencyAccess.objects.create(
                nfc_tag=nfc_tag,
                medical_worker=request.user if request.user.is_authenticated else None,
                ip_address=self._get_client_ip(request),
                device_info=request.META.get('HTTP_USER_AGENT', ''),
                latitude=serializer.validated_data.get('latitude'),
                longitude=serializer.validated_data.get('longitude'),
                data_accessed=profile_data
            )

            return Response({
                'profile': profile_data,
                'message': 'Успешный доступ к экстренным медицинским данным'
            }, status=status.HTTP_200_OK)

        except MedicalProfile.DoesNotExist:
            self._log_access(
                nfc_tag=nfc_tag,
                access_type='SCAN',
                status='FAILED',
                request=request,
                error_message='Medical profile not found'
            )
            return Response(
                {'error': 'Медицинский профиль не найден'},
                status=status.HTTP_404_NOT_FOUND
            )

    def _log_access(self, nfc_tag, access_type, status, request, error_message=''):
        """Helper to log access"""
        NFCAccessLog.objects.create(
            nfc_tag=nfc_tag,
            accessed_by=request.user if request.user.is_authenticated else None,
            access_type=access_type,
            status=status,
            ip_address=self._get_client_ip(request),
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            error_message=error_message
        )

    def _log_failed_scan(self, request, error_message):
        """Log failed scan attempt"""
        NFCAccessLog.objects.create(
            nfc_tag=None,
            accessed_by=request.user if request.user.is_authenticated else None,
            access_type='SCAN',
            status='FAILED',
            ip_address=self._get_client_ip(request),
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            error_message=error_message
        )

    def _get_client_ip(self, request):
        """Get client IP address"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR', '127.0.0.1')
        return ip


class NFCTagRevokeView(APIView):
    """Revoke an NFC tag"""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = NFCTagRevokeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        tag_id = serializer.validated_data['tag_id']
        reason = serializer.validated_data.get('reason', '')

        nfc_tag = get_object_or_404(NFCTag, id=tag_id, user=request.user)

        if not nfc_tag.is_active:
            return Response(
                {'error': 'Метка уже отозвана'},
                status=status.HTTP_400_BAD_REQUEST
            )

        nfc_tag.revoke(reason=reason)

        # Log revocation
        NFCAccessLog.objects.create(
            nfc_tag=nfc_tag,
            accessed_by=request.user,
            access_type='REVOKE',
            status='SUCCESS',
            ip_address=self._get_client_ip(request),
            user_agent=request.META.get('HTTP_USER_AGENT', '')
        )

        return Response({
            'message': 'NFC метка успешно отозвана',
            'tag': NFCTagSerializer(nfc_tag).data
        }, status=status.HTTP_200_OK)

    def _get_client_ip(self, request):
        """Get client IP address"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR', '127.0.0.1')
        return ip


class NFCAccessLogListView(generics.ListAPIView):
    """List access logs for user's NFC tags"""

    serializer_class = NFCAccessLogSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None  # Disable pagination for personal data

    def get_queryset(self):
        user = self.request.user

        if user.is_admin:
            # Admins can see all logs
            return NFCAccessLog.objects.all().order_by('-accessed_at')
        else:
            # Users can see logs for their tags
            return NFCAccessLog.objects.filter(nfc_tag__user=user).order_by('-accessed_at')


class NFCEmergencyAccessListView(generics.ListAPIView):
    """List emergency accesses for user's NFC tags"""

    serializer_class = NFCEmergencyAccessSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None  # Disable pagination for personal data

    def get_queryset(self):
        user = self.request.user

        if user.is_admin:
            # Admins can see all emergency accesses
            return NFCEmergencyAccess.objects.all().order_by('-accessed_at')
        else:
            # Users can see emergency accesses for their tags
            return NFCEmergencyAccess.objects.filter(nfc_tag__user=user).order_by('-accessed_at')


class NFCEmergencyDataView(APIView):
    """Get emergency medical data by NFC tag UID (for QR code access)"""

    permission_classes = [permissions.AllowAny]

    def get(self, request, tag_uid):
        """Get emergency data by tag UID"""
        nfc_tag = get_object_or_404(NFCTag, tag_uid=tag_uid)

        if not nfc_tag.is_active:
            self._log_access(nfc_tag, "SCAN", "DENIED", request, "Tag is not active")
            return Response({"error": "NFC tag inactive"}, status=status.HTTP_403_FORBIDDEN)

        nfc_tag.last_scanned_at = timezone.now()
        nfc_tag.scan_count += 1
        nfc_tag.save(update_fields=["last_scanned_at", "scan_count"])

        try:
            profile = nfc_tag.user.medical_profile
            if not profile.is_public:
                self._log_access(nfc_tag, "SCAN", "DENIED", request, "Profile is private")
                return Response({"error": "Access denied"}, status=status.HTTP_403_FORBIDDEN)

            user = nfc_tag.user
            profile_data = EmergencyProfileSerializer(profile).data

            self._log_access(nfc_tag, "SCAN", "SUCCESS", request)
            NFCEmergencyAccess.objects.create(
                nfc_tag=nfc_tag,
                medical_worker=request.user if request.user.is_authenticated else None,
                ip_address=self._get_client_ip(request),
                device_info=request.META.get("HTTP_USER_AGENT", ""),
                data_accessed=profile_data
            )

            return Response({
                "user": {"full_name": user.get_full_name(), "first_name": user.first_name, "last_name": user.last_name},
                "profile": profile_data,
                "tag": {"name": "Tag " + nfc_tag.tag_uid[:8], "uid": str(nfc_tag.tag_uid)},
                "allergies": profile_data.get("allergies", []),
                "diseases": profile_data.get("chronic_diseases", []),
                "medications": profile_data.get("medications", []),
                "emergency_contacts": profile_data.get("emergency_contacts", []),
            }, status=status.HTTP_200_OK)

        except MedicalProfile.DoesNotExist:
            self._log_access(nfc_tag, "SCAN", "FAILED", request, "Medical profile not found")
            return Response({"error": "Profile not found"}, status=status.HTTP_404_NOT_FOUND)

    def _log_access(self, nfc_tag, access_type, log_status, request, error_message=""):
        NFCAccessLog.objects.create(
            nfc_tag=nfc_tag, accessed_by=request.user if request.user.is_authenticated else None,
            access_type=access_type, status=log_status, ip_address=self._get_client_ip(request),
            user_agent=request.META.get("HTTP_USER_AGENT", ""), error_message=error_message
        )

    def _get_client_ip(self, request):
        x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
        return x_forwarded_for.split(",")[0] if x_forwarded_for else request.META.get("REMOTE_ADDR", "127.0.0.1")

