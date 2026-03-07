import 'package:flutter/material.dart';
import '../../services/nfc_service.dart';

class EmergencyScreen extends StatefulWidget {
  final String tagUid;

  const EmergencyScreen({super.key, required this.tagUid});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final NFCService _nfcService = NFCService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmergencyData();
  }

  Future<void> _loadEmergencyData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final data = await _nfcService.getEmergencyAccess(widget.tagUid);
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
        if (data == null) _error = 'Не удалось загрузить данные пациента';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'ЭКСТРЕННЫЙ ДОСТУП',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[700]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEmergencyData,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Backend returns "user" and "profile" keys
    final patient = (_data?['user'] ?? _data?['patient']) as Map<String, dynamic>?;
    final profile = (_data?['profile'] ?? _data?['medical_profile']) as Map<String, dynamic>?;

    final firstName = patient?['first_name'] ?? '';
    final lastName = patient?['last_name'] ?? '';
    final middleName = patient?['middle_name'] ?? '';
    final fullName = patient?['full_name'] ??
        [lastName, firstName, middleName].where((s) => s.isNotEmpty).join(' ');

    // Data lists — backend may return at top-level OR nested in profile
    final allergies = (profile?['allergies'] ?? _data?['allergies']) as List?;
    final diseases = (profile?['chronic_diseases'] ?? _data?['diseases']) as List?;
    final medications = (profile?['medications'] ?? _data?['medications']) as List?;
    final contacts = (profile?['emergency_contacts'] ?? _data?['emergency_contacts']) as List?;

    return RefreshIndicator(
      onRefresh: _loadEmergencyData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[700],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'МЕДИЦИНСКАЯ ИНФОРМАЦИЯ ДЛЯ ЭКСТРЕННЫХ СЛУЖБ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Patient info card
          _buildCard(
            icon: Icons.person,
            color: Colors.blue[700]!,
            title: 'Пациент',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fullName.isNotEmpty)
                  _buildInfoRow('ФИО', fullName),
                if (profile?['blood_type'] != null)
                  _buildInfoRow('Группа крови', _formatBloodType(profile!['blood_type'])),
                if (profile?['height'] != null)
                  _buildInfoRow('Рост', '${profile!['height']} см'),
                if (profile?['weight'] != null)
                  _buildInfoRow('Вес', '${profile!['weight']} кг'),
              ],
            ),
          ),

          // Emergency notes
          if (profile?['emergency_notes'] != null &&
              (profile!['emergency_notes'] as String).isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.priority_high,
              color: Colors.red[800]!,
              title: 'Важные заметки',
              child: Text(
                profile['emergency_notes'],
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],

          // Allergies
          if (allergies != null && allergies.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.warning,
              color: Colors.orange[700]!,
              title: 'Аллергии',
              child: Column(
                children: allergies.map((a) {
                  final severity = a['severity'] ?? '';
                  return _buildAllergyRow(
                    a['allergen'] ?? '',
                    severity,
                    a['reaction'],
                  );
                }).toList(),
              ),
            ),
          ],

          // Chronic diseases
          if (diseases != null && diseases.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.medical_information,
              color: Colors.purple[700]!,
              title: 'Хронические заболевания',
              child: Column(
                children: diseases.map((d) {
                  return _buildListRow(
                    d['disease_name'] ?? '',
                    subtitle: d['icd_code'] != null && (d['icd_code'] as String).isNotEmpty
                        ? 'МКБ: ${d['icd_code']}'
                        : null,
                  );
                }).toList(),
              ),
            ),
          ],

          // Medications
          if (medications != null && medications.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.medication,
              color: Colors.teal[700]!,
              title: 'Препараты',
              child: Column(
                children: medications
                    .where((m) => m['is_active'] == true)
                    .map((m) {
                  final dosage = m['dosage'] != null && (m['dosage'] as String).isNotEmpty
                      ? ', ${m['dosage']}'
                      : '';
                  final freq = m['frequency'] != null ? ', ${m['frequency']}' : '';
                  return _buildListRow('${m['medication_name']}$dosage$freq');
                }).toList(),
              ),
            ),
          ],

          // Emergency contacts
          if (contacts != null && contacts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.contacts,
              color: Colors.green[700]!,
              title: 'Экстренные контакты',
              child: Column(
                children: contacts.map((c) {
                  return _buildContactRow(
                    c['full_name'] ?? c['name'] ?? '',
                    c['relationship'] ?? '',
                    c['phone'] ?? '',
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyRow(String allergen, String severity, String? reaction) {
    final color = _severityColor(severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, color: color, size: 10),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        allergen,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _severityLabel(severity),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (reaction != null && reaction.isNotEmpty)
                  Text(
                    reaction,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(String text, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(String name, String relation, String phone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name ($relation)',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBloodType(String bloodType) {
    switch (bloodType) {
      case 'I+': return 'I (0) Rh+';
      case 'I-': return 'I (0) Rh-';
      case 'II+': return 'II (A) Rh+';
      case 'II-': return 'II (A) Rh-';
      case 'III+': return 'III (B) Rh+';
      case 'III-': return 'III (B) Rh-';
      case 'IV+': return 'IV (AB) Rh+';
      case 'IV-': return 'IV (AB) Rh-';
      default: return bloodType;
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'LIFE_THREATENING': return Colors.red[900]!;
      case 'SEVERE': return Colors.red[600]!;
      case 'MODERATE': return Colors.orange[700]!;
      case 'MILD': return Colors.green[700]!;
      default: return Colors.grey;
    }
  }

  String _severityLabel(String severity) {
    switch (severity.toUpperCase()) {
      case 'LIFE_THREATENING': return 'УГРОЗА ЖИЗНИ';
      case 'SEVERE': return 'Тяжёлая';
      case 'MODERATE': return 'Умеренная';
      case 'MILD': return 'Лёгкая';
      default: return severity;
    }
  }
}
