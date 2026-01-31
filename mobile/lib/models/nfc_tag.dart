import 'package:flutter/material.dart';

/// NFC Tag model matching Django backend
class NFCTag {
  final int? id;
  final String tagUid;
  final String status;
  final int scanCount;
  final DateTime? registeredAt;
  final DateTime? lastScanned;

  NFCTag({
    this.id,
    required this.tagUid,
    this.status = 'ACTIVE',
    this.scanCount = 0,
    this.registeredAt,
    this.lastScanned,
  });

  factory NFCTag.fromJson(Map<String, dynamic> json) {
    return NFCTag(
      id: json['id'],
      tagUid: json['tag_uid'],
      status: json['status'] ?? 'ACTIVE',
      scanCount: json['scan_count'] ?? 0,
      registeredAt: json['registered_at'] != null
          ? DateTime.parse(json['registered_at'])
          : null,
      lastScanned: json['last_scanned'] != null
          ? DateTime.parse(json['last_scanned'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tag_uid': tagUid,
      'status': status,
      'scan_count': scanCount,
      if (registeredAt != null) 'registered_at': registeredAt!.toIso8601String(),
      if (lastScanned != null) 'last_scanned': lastScanned!.toIso8601String(),
    };
  }

  bool get isActive => status == NFCTagStatus.active;
  bool get isRevoked => status == NFCTagStatus.revoked;
}

/// NFC Tag Status constants
class NFCTagStatus {
  static const String active = 'ACTIVE';
  static const String revoked = 'REVOKED';
  static const String lost = 'LOST';
  static const String replaced = 'REPLACED';

  static const List<String> values = [active, revoked, lost, replaced];

  static String getDisplayName(String status) {
    switch (status) {
      case active:
        return 'Active';
      case revoked:
        return 'Revoked';
      case lost:
        return 'Lost';
      case replaced:
        return 'Replaced';
      default:
        return status;
    }
  }

  static Color getColor(String status) {
    switch (status) {
      case active:
        return const Color(0xFF4CAF50); // Green
      case revoked:
        return const Color(0xFFF44336); // Red
      case lost:
        return const Color(0xFFFF9800); // Orange
      case replaced:
        return const Color(0xFF9E9E9E); // Grey
      default:
        return const Color(0xFF757575);
    }
  }
}

/// NFC Access Log model
class NFCAccessLog {
  final int id;
  final String tagUid;
  final DateTime accessedAt;
  final String? accessorName;
  final String? location;

  NFCAccessLog({
    required this.id,
    required this.tagUid,
    required this.accessedAt,
    this.accessorName,
    this.location,
  });

  factory NFCAccessLog.fromJson(Map<String, dynamic> json) {
    return NFCAccessLog(
      id: json['id'],
      tagUid: json['tag_uid'],
      accessedAt: DateTime.parse(json['accessed_at']),
      accessorName: json['accessor_name'],
      location: json['location'],
    );
  }
}
