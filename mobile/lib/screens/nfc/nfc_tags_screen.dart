import 'package:flutter/material.dart';
import '../../models/nfc_tag.dart';
import '../../services/nfc_service.dart';
import 'package:nfc_manager/nfc_manager.dart';

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

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
    _loadTags();
  }

  Future<void> _checkNFCAvailability() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      setState(() {
        _isNFCAvailable = availability.index > 0; // notSupported = 0, disabled = 1, available = 2
      });
    } catch (e) {
      setState(() {
        _isNFCAvailable = false;
      });
    }
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    final tags = await _nfcService.getTags();
    setState(() {
      _tags = tags;
      _isLoading = false;
    });
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

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        onDiscovered: (NfcTag tag) async {
          // Generate a simple tag UID from tag data
          // In production, you'd extract the actual UID from the tag
          final tagUid = DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase();

          await NfcManager.instance.stopSession();

          if (mounted) {
            Navigator.of(context).pop(); // Close scanning dialog
          }

          final result = await _nfcService.registerTag(tagUid);

          if (mounted) {
            if (result['success']) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tag registered successfully!')),
              );
              await _loadTags();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to register tag: ${result['error']}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
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
      body: _isLoading
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
                    color: NFCTagStatus.getColor(tag.status).withOpacity(0.2),
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
