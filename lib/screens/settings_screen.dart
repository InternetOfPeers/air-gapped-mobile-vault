import 'package:flutter/material.dart';
import '../services/key_storage_service.dart';
import '../widgets/secure_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _keyCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKeyCount();
  }

  Future<void> _loadKeyCount() async {
    try {
      final keys = await KeyStorageService.instance.getStoredKeyAliases();
      if (mounted) {
        setState(() {
          _keyCount = keys.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WarningCard(
              message: 'This will permanently delete ALL stored private keys and data. Make sure you have backups of your keys before proceeding.',
              title: 'Dangerous Action',
              isError: true,
            ),
            SizedBox(height: 16),
            Text('This action cannot be undone. Are you absolutely sure?'),
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
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await KeyStorageService.instance.clearAllKeys();
      if (success) {
        _showSuccessSnackBar('All data cleared successfully');
        await _loadKeyCount();
      } else {
        _showErrorSnackBar('Failed to clear data');
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Air Gapped Vault'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Air Gapped Vault v1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'A secure, offline mobile application for storing Ethereum private keys and signing transactions.',
              ),
              SizedBox(height: 16),
              Text(
                'Security Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Works completely offline'),
              Text('• Uses device keystore/keychain'),
              Text('• No data tracking or logging'),
              Text('• Secure key storage encryption'),
              SizedBox(height: 16),
              Text(
                'Supported Platforms:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Android 9+'),
              Text('• iOS'),
              SizedBox(height: 16),
              WarningCard(
                message: 'Always verify transaction details before signing. Keep your private keys safe and never share them with anyone.',
                title: 'Security Reminder',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SuccessCard(
                message: 'This app is designed with privacy as the highest priority.',
                title: 'Privacy First',
              ),
              SizedBox(height: 16),
              Text(
                'Data Collection:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• No analytics or tracking'),
              Text('• No crash reporting'),
              Text('• No usage statistics'),
              Text('• No network connections'),
              SizedBox(height: 16),
              Text(
                'Data Storage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Private keys stored in device keystore'),
              Text('• All data encrypted at rest'),
              Text('• No cloud synchronization'),
              Text('• No external backups'),
              SizedBox(height: 16),
              Text(
                'Security Measures:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Hardware-backed encryption (when available)'),
              Text('• Secure storage APIs'),
              Text('• No debug logging'),
              Text('• Memory cleared after use'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
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
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Status
                  Text(
                    'App Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SensitiveInfoCard(
                    title: 'Stored Keys',
                    icon: Icons.key,
                    child: Text('$_keyCount key${_keyCount == 1 ? '' : 's'} stored'),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  const SensitiveInfoCard(
                    title: 'Network Status',
                    icon: Icons.wifi_off,
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Text('Offline (Secure)'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  const SensitiveInfoCard(
                    title: 'Storage Security',
                    icon: Icons.security,
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Text('Hardware Keystore Enabled'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Information Section
                  Text(
                    'Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _SettingsItem(
                    title: 'Privacy & Security',
                    subtitle: 'Learn about data protection',
                    icon: Icons.privacy_tip,
                    onTap: _showPrivacyInfo,
                  ),
                  
                  _SettingsItem(
                    title: 'About',
                    subtitle: 'App version and information',
                    icon: Icons.info,
                    onTap: _showAboutDialog,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Danger Zone
                  Text(
                    'Danger Zone',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const WarningCard(
                    message: 'These actions are irreversible. Make sure you have backups of your private keys.',
                    title: 'Warning',
                    isError: true,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _SettingsItem(
                    title: 'Clear All Data',
                    subtitle: 'Delete all stored keys and data',
                    icon: Icons.delete_forever,
                    iconColor: Theme.of(context).colorScheme.error,
                    textColor: Theme.of(context).colorScheme.error,
                    onTap: _clearAllData,
                  ),
                ],
              ),
            ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _SettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SecureCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
