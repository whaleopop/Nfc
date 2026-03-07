import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/nfc_tag.dart';
import '../../services/nfc_service.dart';
import '../../services/profile_service.dart';
import '../../utils/api_config.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/ndef_record.dart';

class NFCTagsScreen extends StatefulWidget {
  const NFCTagsScreen({super.key});

  @override
  State<NFCTagsScreen> createState() => _NFCTagsScreenState();
}

class _NFCTagsScreenState extends State<NFCTagsScreen> {
  final NFCService _nfcService = NFCService();
  List<NFCTag> _tags = [];
  bool _isLoading = true;
  bool _isNFCAvailable = false;
  bool _isTagProcessing = false; // guard against multiple onDiscovered firings

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
    _loadTags();
  }

  Future<void> _checkNFCAvailability() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      final isEnabled = availability.name == 'enabled' || availability.name == 'available';
      final isDisabled = availability.name == 'disabled';

      setState(() {
        _isNFCAvailable = isEnabled;
      });

      if (!isEnabled && mounted) {
        final message = isDisabled
            ? 'NFC отключён. Включите его в Настройках → Подключённые устройства → NFC'
            : 'NFC не поддерживается на этом устройстве';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isNFCAvailable = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка проверки NFC: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    try {
      final tags = await _nfcService.getTags();
      setState(() {
        _tags = tags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _tags = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _scanAndRegisterTag() async {
    if (!_isNFCAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC недоступен на этом устройстве')),
        );
      }
      return;
    }

    // Enforce max 3 active tags — auto-revoke all excess (keep 2, new one makes 3)
    final activeTags = _tags.where((t) => t.isActive).toList();
    if (activeTags.length >= 3) {
      activeTags.sort((a, b) =>
          (a.registeredAt ?? DateTime(0)).compareTo(b.registeredAt ?? DateTime(0)));
      // Revoke oldest ones until only 2 remain
      final toRevoke = activeTags.take(activeTags.length - 2).toList();
      for (final tag in toRevoke) {
        final ok = await _nfcService.revokeTag(tag.id!, 'auto: превышен лимит 3 метки');
        if (!ok) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Не удалось отозвать метку ${tag.tagUid}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
      await _loadTags();
    }

    // Show dialog to inform user to scan
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Сканирование NFC'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Поднесите устройство к NFC метке'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                NfcManager.instance.stopSession();
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
          ],
        ),
      );
    }

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        onDiscovered: (NfcTag tag) async {
          if (_isTagProcessing) return;
          _isTagProcessing = true;
          try {
            // 1. Extract real UID from tag via NfcTagAndroid
            String? tagUid;
            final androidTag = NfcTagAndroid.from(tag);
            if (androidTag != null) {
              tagUid = androidTag.id
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
            }

            if (tagUid == null || tagUid.isEmpty) {
              await NfcManager.instance.stopSession();
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Не удалось прочитать UID метки'), backgroundColor: Colors.red),
                );
              }
              return;
            }

            // 2. Register in backend
            final result = await _nfcService.registerTag(tagUid);

            if (result['success']) {
              // 3. Write NDEF records to tag:
              //    - Record 1 (URI): opens app if installed, else browser
              //    - Record 2 (Text): plain emergency note if no app/internet
              final emergencyUrl = '${ApiConfig.frontendUrl}/emergency/$tagUid';
              final ndef = NdefAndroid.from(tag);
              if (ndef != null && ndef.isWritable) {
                try {
                  // --- URI record ---
                  final urlWithoutScheme = emergencyUrl.replaceFirst('https://', '');
                  final uriPayload = Uint8List.fromList([0x04, ...urlWithoutScheme.codeUnits]);
                  final uriRecord = NdefRecord(
                    typeNameFormat: TypeNameFormat.wellKnown,
                    type: Uint8List.fromList([0x55]), // 'U'
                    identifier: Uint8List(0),
                    payload: uriPayload,
                  );

                  // --- Text record: basic emergency info for offline fallback ---
                  final profileService = ProfileService();
                  final profile = await profileService.getProfile();
                  final allergies = await profileService.getAllergies();
                  final contacts = await profileService.getEmergencyContacts();

                  final buffer = StringBuffer();
                  buffer.writeln('=== ЭКСТРЕННАЯ МЕДКАРТА ===');
                  if (profile != null) {
                    if (profile.bloodType != null && profile.bloodType!.isNotEmpty) {
                      buffer.writeln('Группа крови: ${profile.bloodType}');
                    }
                  }
                  final severeAllergies = allergies.where((a) =>
                      a.severity == 'SEVERE' || a.severity == 'LIFE_THREATENING').toList();
                  if (severeAllergies.isNotEmpty) {
                    buffer.writeln('АЛЛЕРГИИ: ${severeAllergies.map((a) => a.allergen).join(', ')}');
                  }
                  if (contacts.isNotEmpty) {
                    final c = contacts.first;
                    buffer.writeln('Контакт: ${c.name} ${c.phone}');
                  }
                  buffer.write('Данные: $emergencyUrl');

                  final textStr = buffer.toString();
                  final langCode = utf8.encode('ru');
                  final textBytes = utf8.encode(textStr);
                  final textPayload = Uint8List.fromList([
                    langCode.length, // status byte: UTF-8, lang length = 2
                    ...langCode,
                    ...textBytes,
                  ]);
                  final textRecord = NdefRecord(
                    typeNameFormat: TypeNameFormat.wellKnown,
                    type: Uint8List.fromList([0x54]), // 'T'
                    identifier: Uint8List(0),
                    payload: textPayload,
                  );

                  await ndef.writeNdefMessage(NdefMessage(records: [uriRecord, textRecord]));
                } catch (_) {
                  // write failed — tag still registered in backend
                }
              }
            }

            await NfcManager.instance.stopSession();

            if (mounted) {
              Navigator.of(context).pop();
              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Метка зарегистрирована и URL записан!')),
                );
                await _loadTags();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: ${result['error']}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            await NfcManager.instance.stopSession();
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
              );
            }
          } finally {
            _isTagProcessing = false;
          }
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои NFC метки'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_tags.any((t) => t.isActive))
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Отозвать все метки',
              onPressed: _revokeAllTags,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tags.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadTags,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _tags.length,
                          itemBuilder: (context, index) {
                            final tag = _tags[index];
                            return _buildTagCard(tag);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanAndRegisterTag,
        icon: const Icon(Icons.nfc),
        label: const Text('Добавить метку'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.nfc,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Нет NFC меток',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Зарегистрируйте первую NFC метку для начала работы',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _scanAndRegisterTag,
            icon: const Icon(Icons.nfc),
            label: const Text('Добавить метку'),
          ),
        ],
      ),
    );
  }

  Widget _buildTagCard(NFCTag tag) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: NFCTagStatus.getColor(tag.status),
          child: const Icon(Icons.nfc, color: Colors.white),
        ),
        title: Text(
          'Метка: ${tag.tagUid}',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: NFCTagStatus.getColor(tag.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    NFCTagStatus.getDisplayName(tag.status),
                    style: TextStyle(
                      fontSize: 12,
                      color: NFCTagStatus.getColor(tag.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Сканирований: ${tag.scanCount}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (tag.registeredAt != null)
              Text(
                'Зарегистрирована: ${_formatDate(tag.registeredAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: tag.isActive
            ? PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'revoke') {
                    final confirm = await _showRevokeDialog();
                    if (confirm == true) {
                      final success = await _nfcService.revokeTag(tag.id!, null);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Метка отозвана')),
                        );
                        await _loadTags();
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'revoke',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Отозвать метку'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _revokeAllTags() async {
    final activeTags = _tags.where((t) => t.isActive).toList();
    if (activeTags.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отозвать все метки'),
        content: Text(
          'Вы уверены? Все ${activeTags.length} активных меток будут отозваны.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Отозвать все'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    int failed = 0;
    for (final tag in activeTags) {
      final ok = await _nfcService.revokeTag(tag.id!, 'manual: revoke all');
      if (!ok) failed++;
    }

    await _loadTags();

    if (mounted) {
      final revoked = activeTags.length - failed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed == 0
                ? 'Все метки отозваны ($revoked)'
                : 'Отозвано $revoked из ${activeTags.length}',
          ),
          backgroundColor: failed == 0 ? null : Colors.orange,
        ),
      );
    }
  }

  Future<bool?> _showRevokeDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отозвать метку'),
        content: const Text('Вы уверены, что хотите отозвать эту NFC метку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Отозвать'),
          ),
        ],
      ),
    );
  }
}
