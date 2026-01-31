import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/medical_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = profileProvider.profile;

          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medical_information, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No profile found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to create profile screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile creation coming soon')),
                      );
                    },
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Info Card
                _buildSectionCard(
                  title: 'Basic Information',
                  icon: Icons.person,
                  children: [
                    if (profile.bloodType != null)
                      _buildInfoRow(
                        'Blood Type',
                        BloodType.getDisplayName(profile.bloodType!),
                        Icons.bloodtype,
                      ),
                    if (profile.height != null)
                      _buildInfoRow(
                        'Height',
                        '${profile.height} cm',
                        Icons.height,
                      ),
                    if (profile.weight != null)
                      _buildInfoRow(
                        'Weight',
                        '${profile.weight} kg',
                        Icons.monitor_weight,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Allergies Card
                _buildSectionCard(
                  title: 'Allergies',
                  icon: Icons.warning_amber,
                  children: profile.allergies.isEmpty
                      ? [const Text('No allergies recorded')]
                      : profile.allergies
                          .map((allergy) => _buildListTile(
                                title: allergy.allergen,
                                subtitle:
                                    'Severity: ${AllergySeverity.getDisplayName(allergy.severity)}',
                                icon: Icons.warning,
                                iconColor: _getSeverityColor(allergy.severity),
                              ))
                          .toList(),
                ),
                const SizedBox(height: 16),

                // Chronic Diseases Card
                _buildSectionCard(
                  title: 'Chronic Diseases',
                  icon: Icons.local_hospital,
                  children: profile.chronicDiseases.isEmpty
                      ? [const Text('No chronic diseases recorded')]
                      : profile.chronicDiseases
                          .where((d) => d.isActive)
                          .map((disease) => _buildListTile(
                                title: disease.diseaseName,
                                subtitle: disease.icdCode != null
                                    ? 'ICD: ${disease.icdCode}'
                                    : null,
                                icon: Icons.medical_information,
                                iconColor: Colors.orange,
                              ))
                          .toList(),
                ),
                const SizedBox(height: 16),

                // Medications Card
                _buildSectionCard(
                  title: 'Current Medications',
                  icon: Icons.medication,
                  children: profile.medications.isEmpty
                      ? [const Text('No medications recorded')]
                      : profile.medications
                          .where((m) => m.isActive)
                          .map((med) => _buildListTile(
                                title: med.medicationName,
                                subtitle: med.dosage != null && med.frequency != null
                                    ? '${med.dosage} - ${med.frequency}'
                                    : med.dosage ?? med.frequency,
                                icon: Icons.medication_liquid,
                                iconColor: Colors.green,
                              ))
                          .toList(),
                ),
                const SizedBox(height: 16),

                // Emergency Contacts Card
                _buildSectionCard(
                  title: 'Emergency Contacts',
                  icon: Icons.contact_emergency,
                  children: profile.emergencyContacts.isEmpty
                      ? [const Text('No emergency contacts recorded')]
                      : profile.emergencyContacts
                          .map((contact) => _buildListTile(
                                title: contact.name,
                                subtitle: '${contact.relationship} - ${contact.phone}',
                                icon: Icons.phone,
                                iconColor: Colors.red,
                              ))
                          .toList(),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to edit profile
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile editing coming soon')),
          );
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      contentPadding: EdgeInsets.zero,
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case AllergySeverity.mild:
        return Colors.yellow;
      case AllergySeverity.moderate:
        return Colors.orange;
      case AllergySeverity.severe:
        return Colors.deepOrange;
      case AllergySeverity.lifeThreatening:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
