"""
Views for authentication app
"""
from rest_framework import status, generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken as JWTRefreshToken
from django.utils import timezone
from datetime import timedelta
from django_otp.plugins.otp_totp.models import TOTPDevice
import qrcode
import io
import base64

from .models import User, RefreshToken
from .serializers import (
    UserSerializer,
    RegisterSerializer,
    LoginSerializer,
    ChangePasswordSerializer,
    TwoFactorEnableSerializer,
    TwoFactorVerifySerializer
)


class RegisterView(generics.CreateAPIView):
    """User registration"""

    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        return Response({
            'user': UserSerializer(user).data,
            'message': 'Пользователь успешно зарегистрирован'
        }, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    """User login"""

    permission_classes = (permissions.AllowAny,)
    serializer_class = LoginSerializer

    def post(self, request):
        serializer = self.serializer_class(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)

        user = serializer.validated_data['user']

        # Check if 2FA is enabled
        if user.two_factor_enabled:
            # Return temporary token for 2FA verification
            return Response({
                'requires_2fa': True,
                'user_id': str(user.id),
                'message': 'Требуется 2FA верификация'
            }, status=status.HTTP_200_OK)

        # Generate JWT tokens
        refresh = JWTRefreshToken.for_user(user)

        # Save refresh token to database
        refresh_token = RefreshToken.objects.create(
            user=user,
            token=str(refresh),
            expires_at=timezone.now() + timedelta(days=1),
            ip_address=self.get_client_ip(request),
            device_info=request.META.get('HTTP_USER_AGENT', '')
        )

        # Update last login
        user.last_login = timezone.now()
        user.save(update_fields=['last_login'])

        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': UserSerializer(user).data
        }, status=status.HTTP_200_OK)

    def get_client_ip(self, request):
        """Get client IP address"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


class RefreshTokenView(APIView):
    """Refresh access token"""

    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        refresh_token = request.data.get('refresh')

        if not refresh_token:
            return Response({'error': 'Refresh token обязателен'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Verify token in database
            db_token = RefreshToken.objects.get(token=refresh_token, is_active=True)

            if db_token.is_expired:
                db_token.is_active = False
                db_token.save()
                return Response({'error': 'Token истек'}, status=status.HTTP_401_UNAUTHORIZED)

            # Generate new access token
            refresh = JWTRefreshToken(refresh_token)
            access_token = str(refresh.access_token)

            return Response({
                'access': access_token
            }, status=status.HTTP_200_OK)

        except RefreshToken.DoesNotExist:
            return Response({'error': 'Невалидный refresh token'}, status=status.HTTP_401_UNAUTHORIZED)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class LogoutView(APIView):
    """User logout"""

    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        refresh_token = request.data.get('refresh')

        if refresh_token:
            try:
                # Deactivate refresh token
                token = RefreshToken.objects.get(token=refresh_token, user=request.user)
                token.is_active = False
                token.save()
            except RefreshToken.DoesNotExist:
                pass

        return Response({'message': 'Успешный выход'}, status=status.HTTP_200_OK)


class MeView(generics.RetrieveUpdateAPIView):
    """Get/Update current user"""

    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user


class ChangePasswordView(APIView):
    """Change user password"""

    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)

        user = request.user
        user.set_password(serializer.validated_data['new_password'])
        user.save()

        # Deactivate all refresh tokens
        RefreshToken.objects.filter(user=user, is_active=True).update(is_active=False)

        return Response({'message': 'Пароль успешно изменен'}, status=status.HTTP_200_OK)


class TwoFactorEnableView(APIView):
    """Enable 2FA for user"""

    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        """Get QR code for 2FA setup"""
        user = request.user

        # Create or get TOTP device
        device, created = TOTPDevice.objects.get_or_create(
            user=user,
            name='default',
            defaults={'confirmed': False}
        )

        # Generate QR code
        url = device.config_url
        qr = qrcode.make(url)

        # Convert to base64
        buffer = io.BytesIO()
        qr.save(buffer, format='PNG')
        qr_base64 = base64.b64encode(buffer.getvalue()).decode()

        return Response({
            'qr_code': f'data:image/png;base64,{qr_base64}',
            'secret': device.key
        }, status=status.HTTP_200_OK)

    def post(self, request):
        """Confirm 2FA setup"""
        serializer = TwoFactorEnableSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user
        otp_code = serializer.validated_data['otp_code']

        try:
            device = TOTPDevice.objects.get(user=user, name='default')

            if device.verify_token(otp_code):
                device.confirmed = True
                device.save()

                user.two_factor_enabled = True
                user.save()

                return Response({'message': '2FA успешно активирован'}, status=status.HTTP_200_OK)
            else:
                return Response({'error': 'Неверный код'}, status=status.HTTP_400_BAD_REQUEST)

        except TOTPDevice.DoesNotExist:
            return Response({'error': 'Устройство не найдено'}, status=status.HTTP_404_NOT_FOUND)


class TwoFactorVerifyView(APIView):
    """Verify 2FA code during login"""

    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        serializer = TwoFactorVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user_id = request.data.get('user_id')
        otp_code = serializer.validated_data['otp_code']

        try:
            user = User.objects.get(id=user_id)
            device = TOTPDevice.objects.get(user=user, name='default', confirmed=True)

            if device.verify_token(otp_code):
                # Generate JWT tokens
                refresh = JWTRefreshToken.for_user(user)

                # Save refresh token to database
                RefreshToken.objects.create(
                    user=user,
                    token=str(refresh),
                    expires_at=timezone.now() + timedelta(days=1),
                    ip_address=self.get_client_ip(request),
                    device_info=request.META.get('HTTP_USER_AGENT', '')
                )

                # Update last login
                user.last_login = timezone.now()
                user.save(update_fields=['last_login'])

                return Response({
                    'access': str(refresh.access_token),
                    'refresh': str(refresh),
                    'user': UserSerializer(user).data
                }, status=status.HTTP_200_OK)
            else:
                return Response({'error': 'Неверный код'}, status=status.HTTP_400_BAD_REQUEST)

        except (User.DoesNotExist, TOTPDevice.DoesNotExist):
            return Response({'error': 'Пользователь или устройство не найдено'}, status=status.HTTP_404_NOT_FOUND)

    def get_client_ip(self, request):
        """Get client IP address"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
