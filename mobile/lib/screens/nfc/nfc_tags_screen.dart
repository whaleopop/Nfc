import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/nfc_tag.dart';
import '../../services/nfc_service.dart';
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
  final List<String> _debugLogs = [];

  void _addLog(String log) {
    setState(() {
      _debugLogs.add('${DateTime.now().toString().substring(11, 19)}: $log');
      if (_debugLogs.length > 50) {
        _debugLogs.removeAt(0);
      }
    });
    print(log);
  }

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
    _loadTags();
  }

  Future<void> _checkNFCAvailability() async {
    try {
      _addLog('Checking NFC availability...');
      final availability = await NfcManager.instance.checkAvailability();
      _addLog('NFC availability result: $availability');
      _addLog('NFC availability index: ${availability.index}');
      _addLog('NFC availability name: ${availability.name}');

      // Check by name, not index, as different platforms may have different enum orders
      final isEnabled = availability.name == 'enabled' || availability.name == 'available';
      final isDisabled = availability.name == 'disabled';

      setState(() {
        _isNFCAvailable = isEnabled;
      });

      String message = '';
      if (isEnabled) {
        message = 'NFC is available and ready';
      } else if (isDisabled) {
        message = 'NFC is disabled. Please enable it in Settings → Connected devices → NFC';
      } else {
        message = 'NFC is not supported on this device';
      }

      _addLog('NFC status: $message');

      if (!isEnabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 5),
            action: isDisabled
                ? SnackBarAction(
                    label: 'Open Settings',
                    onPressed: () {
                      // TODO: Open NFC settings
                    },
                  )
                : null,
          ),
        );
      }
    } catch (e, stackTrace) {
      _addLog('NFC check error: $e');
      _addLog('Stack trace: $stackTrace');
      setState(() {
        _isNFCAvailable = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking NFC: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadTags() async {
    _addLog('Loading NFC tags from API...');
    setState(() => _isLoading = true);
    try {
      final tags = await _nfcService.getTags();
      _addLog('Loaded ${tags.length} tags successfully');
      setState(() {
        _tags = tags;
        _isLoading = false;
      });
    } catch (e) {
      _addLog('Error loading tags: $e');
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
          const SnackBar(content: Text('NFC is not available on this device')),
        );
      }
      return;
    }

    // Show dialog to inform user to scan
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Scan NFC Tag'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Hold your device near the NFC tag'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                NfcManager.instance.stopSession();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

    // Enforce max 3 active tags — auto-revoke oldest if needed
    final activeTags = _tags.where((t) => t.isActive).toList();
    if (activeTags.length >= 3) {
      activeTags.sort((a, b) =>
          (a.registeredAt ?? DateTime(0)).compareTo(b.registeredAt ?? DateTime(0)));
      final oldest = activeTags.first;
      _addLog('Лимит 3 метки: отзываем старейшую ${oldest.tagUid}');
      final revoked = await _nfcService.revokeTag(oldest.id!, 'auto: превышен лимит 3 метки');
      if (!revoked) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось отозвать старую метку'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      _addLog('Старая метка отозвана: ${oldest.tagUid}');
      await _loadTags();
    }

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        onDiscovered: (NfcTag tag) async {
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

            _addLog('Real tag UID: $tagUid');

            // 2. Register in backend
            final result = await _nfcService.registerTag(tagUid);

            if (result['success']) {
              // 3. Write emergency URL to tag as NDEF URI record
              final emergencyUrl = '${ApiConfig.frontendUrl}/emergency/$tagUid';
              final ndef = NdefAndroid.from(tag);
              if (ndef != null && ndef.isWritable) {
                try {
                  // URI record: TNF=wellKnown, type='U', payload=[0x04, ...url without "https://"]
                  final urlWithoutScheme = emergencyUrl.replaceFirst('https://', '');
                  final payload = Uint8List.fromList([0x04, ...urlWithoutScheme.codeUnits]);
                  final uriRecord = NdefRecord(
                    typeNameFormat: TypeNameFormat.wellKnown,
                    type: Uint8List.fromList([0x55]), // 'U'
                    identifier: Uint8List(0),
                    payload: payload,
                  );
                  await ndef.writeNdefMessage(NdefMessage(records: [uriRecord]));
                  _addLog('URL written to tag: $emergencyUrl');
                } catch (e) {
                  _addLog('Warning: Could not write URL: $e');
                }
              } else {
                _addLog('Warning: Tag is not NDEF writable');
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
          }
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
        title: const Text('My NFC Tags'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Debug logs panel
          Container(
            color: Colors.black87,
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[900],
                  child: Row(
                    children: [
                      const Icon(Icons.bug_report, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'DEBUG LOGS',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white, size: 16),
                        onPressed: () {
                          setState(() {
                            _debugLogs.clear();
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _debugLogs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _debugLogs[index],
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Main content
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
        label: const Text('Register New Tag'),
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
            'No NFC Tags',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Register your first NFC tag to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _scanAndRegisterTag,
            icon: const Icon(Icons.nfc),
            label: const Text('Register New Tag'),
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
          'Tag: ${tag.tagUid}',
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
                  'Scans: ${tag.scanCount}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (tag.registeredAt != null)
              Text(
                'Registered: ${_formatDate(tag.registeredAt!)}',
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
                          const SnackBar(content: Text('Tag revoked')),
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
                        Text('Revoke Tag'),
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

  Future<bool?> _showRevokeDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Tag'),
        content: const Text('Are you sure you want to revoke this NFC tag?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }
}
