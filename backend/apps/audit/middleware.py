"""
Audit middleware for automatic logging
"""
from django.utils.deprecation import MiddlewareMixin
from .models import AuditLog
import json


class AuditLogMiddleware(MiddlewareMixin):
    """Middleware to automatically log API requests"""

    # Endpoints to skip logging
    SKIP_ENDPOINTS = [
        '/admin/',
        '/static/',
        '/media/',
        '/api/schema/',
        '/api/docs/',
        '/api/redoc/',
    ]

    # Sensitive fields to exclude from logging
    SENSITIVE_FIELDS = [
        'password', 'password1', 'password2',
        'old_password', 'new_password',
        'token', 'access', 'refresh',
        'secret_key', 'api_key'
    ]

    def process_response(self, request, response):
        """Log the request after processing"""

        # Skip certain endpoints
        if any(request.path.startswith(skip) for skip in self.SKIP_ENDPOINTS):
            return response

        # Only log API endpoints
        if not request.path.startswith('/api/'):
            return response

        # Determine action from method
        action_map = {
            'POST': 'CREATE',
            'PUT': 'UPDATE',
            'PATCH': 'UPDATE',
            'DELETE': 'DELETE',
            'GET': 'READ',
        }
        action = action_map.get(request.method, 'OTHER')

        # Get user
        user = request.user if request.user.is_authenticated else None

        # Get request data (sanitized)
        request_data = self._get_request_data(request)

        # Determine resource type from path
        resource_type = self._determine_resource_type(request.path)

        # Determine severity
        severity = 'LOW'
        if action in ['DELETE', 'UPDATE']:
            severity = 'MEDIUM'
        if not response.status_code < 400:
            severity = 'HIGH'

        # Determine success
        success = response.status_code < 400

        # Get error message if failed
        error_message = ''
        if not success:
            try:
                error_data = json.loads(response.content.decode('utf-8'))
                error_message = str(error_data)
            except:
                error_message = f'HTTP {response.status_code}'

        # Create audit log entry (async would be better)
        try:
            AuditLog.objects.create(
                user=user,
                action=action,
                resource_type=resource_type,
                description=f"{request.method} {request.path}",
                severity=severity,
                ip_address=self._get_client_ip(request),
                user_agent=request.META.get('HTTP_USER_AGENT', ''),
                endpoint=request.path,
                method=request.method,
                new_value=request_data if action in ['CREATE', 'UPDATE'] else None,
                success=success,
                error_message=error_message
            )
        except Exception as e:
            # Don't break the request if audit logging fails
            print(f"Audit logging failed: {e}")

        return response

    def _get_request_data(self, request):
        """Get sanitized request data"""
        try:
            if request.method in ['POST', 'PUT', 'PATCH']:
                data = request.POST.dict() if request.POST else {}

                if not data and hasattr(request, 'body'):
                    try:
                        data = json.loads(request.body.decode('utf-8'))
                    except:
                        data = {}

                # Remove sensitive fields
                return self._sanitize_data(data)
        except:
            pass
        return {}

    def _sanitize_data(self, data):
        """Remove sensitive fields from data"""
        if isinstance(data, dict):
            return {
                k: '***REDACTED***' if k in self.SENSITIVE_FIELDS else v
                for k, v in data.items()
            }
        return data

    def _determine_resource_type(self, path):
        """Determine resource type from path"""
        if '/profile/' in path:
            return 'PROFILE'
        elif '/nfc/' in path:
            return 'NFC_TAG'
        elif '/auth/' in path:
            return 'USER'
        else:
            return 'SYSTEM'

    def _get_client_ip(self, request):
        """Get client IP address"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR', '127.0.0.1')
        return ip
