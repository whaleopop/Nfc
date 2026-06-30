"""
URLs for audit app
"""
from django.urls import path
from .views import (
    AuditLogListView,
    SecurityEventListView,
    MyAuditLogListView,
)

app_name = 'audit'

urlpatterns = [
    path('logs/', AuditLogListView.as_view(), name='audit-log-list'),
    path('security-events/', SecurityEventListView.as_view(), name='security-event-list'),
    path('my-logs/', MyAuditLogListView.as_view(), name='my-audit-log-list'),
]
