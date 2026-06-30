"""
URLs for NFC app
"""
from django.urls import path
from .views import (
    NFCTagListView,
    NFCTagRegisterView,
    NFCTagScanView,
    NFCTagRevokeView,
    NFCAccessLogListView,
    NFCEmergencyAccessListView,
    NFCEmergencyDataView,
)

app_name = 'nfc'

urlpatterns = [
    # NFC Tags
    path('tags/', NFCTagListView.as_view(), name='tag-list'),
    path('register/', NFCTagRegisterView.as_view(), name='register'),
    path('scan/', NFCTagScanView.as_view(), name='scan'),
    path('revoke/', NFCTagRevokeView.as_view(), name='revoke'),

    # Public emergency access (for QR code)
    path('emergency/<str:tag_uid>/', NFCEmergencyDataView.as_view(), name='emergency-data'),

    # Logs
    path('access-logs/', NFCAccessLogListView.as_view(), name='access-log-list'),
    path('emergency-accesses/', NFCEmergencyAccessListView.as_view(), name='emergency-access-list'),
]
