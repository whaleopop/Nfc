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
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _emergencyNotesController = TextEditingController();
  String? _selectedBloodType;
  bool _savingBasicInfo = false;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).loadProfile();
    });
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _emergencyNotesController.dispose();
    super.dispose();
  }

  void _initControllers(MedicalProfile profile) {
    if (!_controllersInitialized) {
      _heightController.text = profile.height?.toString() ?? '';
      _weightController.text = profile.weight?.toString() ?? '';
      _emergencyNotesController.text = profile.emergencyNotes ?? '';
      _selectedBloodType = profile.bloodType;
      _controllersInitialized = true;
    }
  }

  Future<void> _saveBasicInfo(ProfileProvider provider) async {
    setState(() => _savingBasicInfo = true);
    final profile = MedicalProfile(
      id: provider.profile?.id,
      bloodType: _selectedBloodType,
      height: double.tryParse(_heightController.text),
      weight: double.tryParse(_weightController.text),
      emergencyNotes: _emergencyNotesController.text.isEmpty
          ? null
          : _emergencyNotesController.text,
    );
    final success = await provider.saveProfile(profile);
    if (success) _controllersInitialized = false; // reload controllers on next build
    setState(() => _savingBasicInfo = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Профиль сохранён' : 'Ошибка сохранения'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  // ── Allergy dialog ────────────────────────────────────────────────────────
  void _showAllergyDialog(ProfileProvider provider, {Allergy? editing}) {
    final allergenCtrl = TextEditingController(text: editing?.allergen ?? '');
    final reactionCtrl = TextEditingController(text: editing?.reaction ?? '');
    String severity = editing?.severity ?? 'MODERATE';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(editing != null ? 'Редактировать аллергию' : 'Добавить аллергию'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: allergenCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Аллерген',
                    hintText: 'Например: Пенициллин, Арахис',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reactionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Реакция',
                    hintText: 'Описание реакции',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: const InputDecoration(
                    labelText: 'Степень тяжести',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MILD', child: Text('Лёгкая')),
                    DropdownMenuItem(value: 'MODERATE', child: Text('Средняя')),
                    DropdownMenuItem(value: 'SEVERE', child: Text('Тяжёлая')),
                    DropdownMenuItem(
                        value: 'LIFE_THREATENING',
                        child: Text('Опасная для жизни')),
                  ],
                  onChanged: (v) => setLocal(() => severity = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (allergenCtrl.text.trim().isEmpty) return;
                final allergy = Allergy(
                  id: editing?.id,
                  allergen: allergenCtrl.text.trim(),
                  severity: severity,
                  reaction: reactionCtrl.text.isEmpty ? null : reactionCtrl.text,
                );
                Navigator.pop(ctx);
                final ok = editing != null
                    ? await provider.updateAllergy(allergy)
                    : await provider.addAllergy(allergy);
                if (mounted) _showSnack(ok, editing != null ? 'Аллергия обновлена' : 'Аллергия добавлена');
              },
              child: Text(editing != null ? 'Сохранить' : 'Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Disease dialog ────────────────────────────────────────────────────────
  void _showDiseaseDialog(ProfileProvider provider, {ChronicDisease? editing}) {
    final nameCtrl = TextEditingController(text: editing?.diseaseName ?? '');
    final notesCtrl = TextEditingController(text: editing?.notes ?? '');
    final dateCtrl = TextEditingController(
      text: editing?.diagnosisDate != null
          ? editing!.diagnosisDate!.toIso8601String().split('T')[0]
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editing != null ? 'Редактировать заболевание' : 'Добавить заболевание'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Название заболевания',
                  hintText: 'Например: Гипертония, Диабет 2 типа',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Дата диагностирования',
                  hintText: 'ГГГГ-ММ-ДД',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Заметки',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final disease = ChronicDisease(
                id: editing?.id,
                diseaseName: nameCtrl.text.trim(),
                diagnosisDate: dateCtrl.text.isNotEmpty
                    ? DateTime.tryParse(dateCtrl.text)
                    : null,
                notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
              );
              Navigator.pop(ctx);
              final ok = editing != null
                  ? await provider.updateChronicDisease(disease)
                  : await provider.addChronicDisease(disease);
              if (mounted) _showSnack(ok, editing != null ? 'Заболевание обновлено' : 'Заболевание добавлено');
            },
            child: Text(editing != null ? 'Сохранить' : 'Добавить'),
          ),
        ],
      ),
    );
  }

  // ── Medication dialog ─────────────────────────────────────────────────────
  void _showMedicationDialog(ProfileProvider provider, {Medication? editing}) {
    final nameCtrl = TextEditingController(text: editing?.medicationName ?? '');
    final dosageCtrl = TextEditingController(text: editing?.dosage ?? '');
    String frequency = editing?.frequency ?? 'ONCE_DAILY';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(editing != null ? 'Редактировать препарат' : 'Добавить препарат'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Название препарата',
                    hintText: 'Например: Амлодипин, Метформин',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Дозировка',
                    hintText: 'Например: 5 мг, 500 мг',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(
                    labelText: 'Частота приёма',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ONCE_DAILY', child: Text('1 раз в день')),
                    DropdownMenuItem(value: 'TWICE_DAILY', child: Text('2 раза в день')),
                    DropdownMenuItem(value: 'THREE_TIMES_DAILY', child: Text('3 раза в день')),
                    DropdownMenuItem(value: 'FOUR_TIMES_DAILY', child: Text('4 раза в день')),
                    DropdownMenuItem(value: 'AS_NEEDED', child: Text('По необходимости')),
                    DropdownMenuItem(value: 'WEEKLY', child: Text('Еженедельно')),
                    DropdownMenuItem(value: 'MONTHLY', child: Text('Ежемесячно')),
                  ],
                  onChanged: (v) => setLocal(() => frequency = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final med = Medication(
                  id: editing?.id,
                  medicationName: nameCtrl.text.trim(),
                  dosage: dosageCtrl.text.isEmpty ? null : dosageCtrl.text,
                  frequency: frequency,
                );
                Navigator.pop(ctx);
                final ok = editing != null
                    ? await provider.updateMedication(med)
                    : await provider.addMedication(med);
                if (mounted) _showSnack(ok, editing != null ? 'Препарат обновлён' : 'Препарат добавлен');
              },
              child: Text(editing != null ? 'Сохранить' : 'Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Contact dialog ────────────────────────────────────────────────────────
  void _showContactDialog(ProfileProvider provider, {EmergencyContact? editing}) {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final relationCtrl = TextEditingController(text: editing?.relationship ?? '');
    final phoneCtrl = TextEditingController(text: editing?.phone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editing != null ? 'Редактировать контакт' : 'Добавить контакт'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'ФИО',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Отношение',
                  hintText: 'Например: Супруг/Супруга, Родитель',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
              final contact = EmergencyContact(
                id: editing?.id,
                name: nameCtrl.text.trim(),
                relationship: relationCtrl.text.isEmpty ? 'Другое' : relationCtrl.text,
                phone: phoneCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              final ok = editing != null
                  ? await provider.updateEmergencyContact(contact)
                  : await provider.addEmergencyContact(contact);
              if (mounted) _showSnack(ok, editing != null ? 'Контакт обновлён' : 'Контакт добавлен');
            },
            child: Text(editing != null ? 'Сохранить' : 'Добавить'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _showSnack(bool success, String successMsg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? successMsg : 'Ошибка'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  Future<void> _confirmDelete(String what, VoidCallback onConfirm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить $what?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  String _severityLabel(String s) {
    switch (s) {
      case 'MILD': return 'Лёгкая';
      case 'MODERATE': return 'Средняя';
      case 'SEVERE': return 'Тяжёлая';
      case 'LIFE_THREATENING': return 'Опасная для жизни';
      default: return s;
    }
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'MILD': return Colors.yellow[700]!;
      case 'MODERATE': return Colors.orange;
      case 'SEVERE': return Colors.deepOrange;
      case 'LIFE_THREATENING': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _frequencyLabel(String? f) {
    switch (f) {
      case 'ONCE_DAILY': return '1 раз в день';
      case 'TWICE_DAILY': return '2 раза в день';
      case 'THREE_TIMES_DAILY': return '3 раза в день';
      case 'FOUR_TIMES_DAILY': return '4 раза в день';
      case 'AS_NEEDED': return 'По необходимости';
      case 'WEEKLY': return 'Еженедельно';
      case 'MONTHLY': return 'Ежемесячно';
      default: return f ?? '';
    }
  }

  Widget _sectionHeader(String title, IconData icon, VoidCallback onAdd) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: Theme.of(context).colorScheme.primary,
          onPressed: onAdd,
          tooltip: 'Добавить',
        ),
      ],
    );
  }

  Widget _itemActions(VoidCallback onEdit, VoidCallback onDelete) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: onEdit,
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
          onPressed: onDelete,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Медицинский профиль'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = provider.profile;
          if (profile != null) _initControllers(profile);

          return RefreshIndicator(
            onRefresh: () => provider.loadProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Основная информация ──────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Основная информация',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          DropdownButtonFormField<String>(
                            value: _selectedBloodType,
                            decoration: const InputDecoration(
                              labelText: 'Группа крови',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: BloodType.values
                                .map((bt) => DropdownMenuItem(
                                      value: bt,
                                      child: Text(BloodType.getDisplayName(bt)),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedBloodType = v),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _heightController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Рост (см)',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Вес (кг)',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emergencyNotesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Экстренные заметки',
                              hintText:
                                  'Важная информация для медиков в экстренной ситуации...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: _savingBasicInfo
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(_savingBasicInfo
                                  ? 'Сохранение...'
                                  : 'Сохранить'),
                              onPressed: _savingBasicInfo
                                  ? null
                                  : () => _saveBasicInfo(provider),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Аллергии ─────────────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Аллергии', Icons.warning_amber,
                              () => _showAllergyDialog(provider)),
                          const Divider(height: 16),
                          if (profile == null || profile.allergies.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('Нет данных об аллергиях',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          else
                            ...profile.allergies.map((a) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.warning,
                                      color: _severityColor(a.severity)),
                                  title: Text(a.allergen),
                                  subtitle: Text(_severityLabel(a.severity)),
                                  trailing: _itemActions(
                                    () => _showAllergyDialog(provider,
                                        editing: a),
                                    () => _confirmDelete('аллергию',
                                        () => provider.deleteAllergy(a.id!)),
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Хронические заболевания ───────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                              'Хронические заболевания',
                              Icons.local_hospital,
                              () => _showDiseaseDialog(provider)),
                          const Divider(height: 16),
                          if (profile == null || profile.chronicDiseases.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('Нет данных о заболеваниях',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          else
                            ...profile.chronicDiseases.map((d) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.medical_information,
                                      color: Colors.orange),
                                  title: Text(d.diseaseName),
                                  subtitle: d.diagnosisDate != null
                                      ? Text(
                                          'Диагностировано: ${d.diagnosisDate!.day.toString().padLeft(2, '0')}.${d.diagnosisDate!.month.toString().padLeft(2, '0')}.${d.diagnosisDate!.year}')
                                      : null,
                                  trailing: _itemActions(
                                    () => _showDiseaseDialog(provider,
                                        editing: d),
                                    () => _confirmDelete(
                                        'заболевание',
                                        () => provider
                                            .deleteChronicDisease(d.id!)),
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Препараты ─────────────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Принимаемые препараты', Icons.medication,
                              () => _showMedicationDialog(provider)),
                          const Divider(height: 16),
                          if (profile == null || profile.medications.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('Нет данных о препаратах',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          else
                            ...profile.medications
                                .where((m) => m.isActive)
                                .map((m) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                          Icons.medication_liquid,
                                          color: Colors.green),
                                      title: Text(m.medicationName),
                                      subtitle: Text([
                                        if (m.dosage != null) m.dosage!,
                                        if (m.frequency != null)
                                          _frequencyLabel(m.frequency),
                                      ].join(' — ')),
                                      trailing: _itemActions(
                                        () => _showMedicationDialog(provider,
                                            editing: m),
                                        () => _confirmDelete('препарат',
                                            () => provider.deleteMedication(m.id!)),
                                      ),
                                    )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Экстренные контакты ───────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                              'Экстренные контакты',
                              Icons.contact_emergency,
                              () => _showContactDialog(provider)),
                          const Divider(height: 16),
                          if (profile == null ||
                              profile.emergencyContacts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('Добавьте хотя бы один контакт',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          else
                            ...profile.emergencyContacts.map((c) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.phone,
                                      color: Colors.red),
                                  title: Text(c.name),
                                  subtitle: Text(
                                      '${c.relationship} — ${c.phone}'),
                                  trailing: _itemActions(
                                    () => _showContactDialog(provider,
                                        editing: c),
                                    () => _confirmDelete(
                                        'контакт',
                                        () => provider
                                            .deleteEmergencyContact(c.id!)),
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
