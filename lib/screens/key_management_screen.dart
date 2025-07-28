import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/key_storage_service.dart';
import '../widgets/secure_card.dart';
import 'qr_private_key_scanner_screen.dart';

class KeyManagementScreen extends StatefulWidget {
  const KeyManagementScreen({super.key});

  @override
  State<KeyManagementScreen> createState() => _KeyManagementScreenState();
}

class _KeyManagementScreenState extends State<KeyManagementScreen> {
  List<String> _storedKeys = [];
  bool _isLoading = true;
  final _aliasController = TextEditingController();
  final _privateKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStoredKeys();
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredKeys() async {
    try {
      final keys = await KeyStorageService.instance.getStoredKeyAliases();
      if (mounted) {
        setState(() {
          _storedKeys = keys;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load stored keys');
      }
    }
  }

  Future<void> _importPrivateKey() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Private Key'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const WarningCard(
                message: 'Never share your private key with anyone. Make sure you are in a secure environment.',
                title: 'Security Warning',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _aliasController,
                decoration: const InputDecoration(
                  labelText: 'Key Alias',
                  hintText: 'e.g., My Main Key',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _privateKeyController,
                decoration: const InputDecoration(
                  labelText: 'Private Key (Hex)',
                  hintText: '0x...',
                ),
                obscureText: true,
                maxLines: 1,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _aliasController.clear();
              _privateKeyController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _performImportKey,
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _performImportKey() async {
    final alias = _aliasController.text.trim();
    final privateKey = _privateKeyController.text.trim();

    if (alias.isEmpty || privateKey.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    // Check if alias already exists
    if (await KeyStorageService.instance.hasKey(alias)) {
      _showErrorSnackBar('A key with this alias already exists');
      return;
    }

    // Store the key
    final success = await KeyStorageService.instance.storePrivateKey(alias, privateKey);
    
    if (success) {
      _aliasController.clear();
      _privateKeyController.clear();
      Navigator.pop(context);
      _showSuccessSnackBar('Private key imported successfully');
      await _loadStoredKeys();
    } else {
      _showErrorSnackBar('Failed to import private key. Please check the format.');
    }
  }

  Future<void> _deleteKey(String alias) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Private Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WarningCard(
              message: 'This action cannot be undone. Make sure you have a backup of your private key.',
              title: 'Warning',
              isError: true,
            ),
            const SizedBox(height: 16),
            Text('Are you sure you want to delete the key "$alias"?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await KeyStorageService.instance.deletePrivateKey(alias);
      if (success) {
        _showSuccessSnackBar('Private key deleted successfully');
        await _loadStoredKeys();
      } else {
        _showErrorSnackBar('Failed to delete private key');
      }
    }
  }

  Future<void> _showKeyDetails(String alias) async {
    final privateKey = await KeyStorageService.instance.getPrivateKey(alias);
    if (privateKey == null) {
      _showErrorSnackBar('Failed to retrieve private key');
      return;
    }

    final fingerprint = KeyStorageService.instance.getKeyFingerprint(privateKey);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Key Details: $alias'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SensitiveInfoCard(
                title: 'Key Fingerprint',
                icon: Icons.fingerprint,
                child: Text(
                  fingerprint,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SensitiveInfoCard(
                title: 'Private Key',
                icon: Icons.key,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${privateKey.substring(0, 10)}...${privateKey.substring(privateKey.length - 10)}',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: privateKey));
                              _showSuccessSnackBar('Private key copied to clipboard');
                            },
                            child: const Text('Copy'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const WarningCard(
                message: 'Never share your private key with anyone. Clear your clipboard after use.',
                title: 'Security Reminder',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Key Management'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (value) {
              if (value == 'qr') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRPrivateKeyScannerScreen(),
                  ),
                ).then((_) => _loadStoredKeys());
              } else if (value == 'manual') {
                _importPrivateKey();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'qr',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner),
                    SizedBox(width: 8),
                    Text('Scan QR Code'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'manual',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Manual Entry'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStoredKeys,
              child: _storedKeys.isEmpty
                  ? _buildEmptyState()
                  : _buildKeysList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.key_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'No Private Keys Stored',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Import your first private key to get started with signing transactions.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Import options
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QRPrivateKeyScannerScreen(),
                      ),
                    ).then((_) => _loadStoredKeys());
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _importPrivateKey,
                  icon: const Icon(Icons.edit),
                  label: const Text('Manual Entry'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeysList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _storedKeys.length,
      itemBuilder: (context, index) {
        final alias = _storedKeys[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SecureCard(
            onTap: () => _showKeyDetails(alias),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.key,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alias,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to view details',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        _showKeyDetails(alias);
                        break;
                      case 'delete':
                        _deleteKey(alias);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
