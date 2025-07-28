import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_code_service.dart';
import '../services/key_storage_service.dart';
import '../widgets/secure_card.dart';

class QRPrivateKeyScannerScreen extends StatefulWidget {
  const QRPrivateKeyScannerScreen({super.key});

  @override
  State<QRPrivateKeyScannerScreen> createState() => _QRPrivateKeyScannerScreenState();
}

class _QRPrivateKeyScannerScreenState extends State<QRPrivateKeyScannerScreen> {
  MobileScannerController? _controller;
  bool _hasPermission = false;
  bool _isScanning = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
    _checkPermission();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await QRCodeService.instance.hasCameraPermission();
    if (!hasPermission) {
      final granted = await QRCodeService.instance.requestCameraPermission();
      setState(() {
        _hasPermission = granted;
      });
      if (!granted) {
        _showErrorDialogAndClose('Camera permission is required to scan QR codes.');
      }
    } else {
      setState(() {
        _hasPermission = true;
      });
    }
  }

  void _handleDetection(BarcodeCapture capture) {
    if (!_isScanning || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _handleScannedData(barcode.rawValue!);
        break;
      }
    }
  }

  void _handleScannedData(String data) {
    setState(() {
      _isScanning = false;
      _isProcessing = true;
    });

    final processedData = QRCodeService.instance.processQRData(data);
    if (processedData == null) {
      _showDetailedErrorDialog(data);
      return;
    }

    // Check if it's specifically a private key
    if (!QRCodeService.instance.isValidPrivateKey(processedData)) {
      _showWrongTypeErrorDialog(data, processedData);
      return;
    }

    _showImportPrivateKeyDialog(processedData);
  }

  void _showImportPrivateKeyDialog(String privateKey) {
    final aliasController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.key,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Private Key Detected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WarningCard(
              message: 'Make sure you trust the source of this QR code.',
              title: 'Security Warning',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: aliasController,
              decoration: const InputDecoration(
                labelText: 'Key Alias',
                hintText: 'e.g., My Wallet Key',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            SensitiveInfoCard(
              title: 'Private Key Preview',
              icon: Icons.key,
              child: Text(
                '${privateKey.substring(0, 10)}...${privateKey.substring(privateKey.length - 10)}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              aliasController.dispose();
              Navigator.pop(context);
              _closeScanner();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final alias = aliasController.text.trim();
              if (alias.isEmpty) {
                _showErrorSnackBar('Please enter a key alias');
                return;
              }

              if (await KeyStorageService.instance.hasKey(alias)) {
                _showErrorSnackBar('A key with this alias already exists');
                return;
              }

              final success = await KeyStorageService.instance.storePrivateKey(alias, privateKey);
              aliasController.dispose();
              Navigator.pop(context);

              if (success) {
                _showSuccessDialogAndClose('Private key imported successfully!');
              } else {
                _showErrorDialogAndClose('Failed to import private key.');
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showDetailedErrorDialog(String rawData) {
    String analysisResult = '';
    final privateKeyInfo = QRCodeService.instance.getPrivateKeyValidationInfo(rawData);
    analysisResult = 'Private Key Analysis: $privateKeyInfo';

    String expectedFormat = '''Expected Format:

🔑 Private Key:
• Exactly 64 hexadecimal characters
• With or without '0x' prefix
• Must be within valid secp256k1 curve range
• Example: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef''';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Invalid Private Key QR Code')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The scanned QR code does not contain a valid private key.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              // Analysis section
              Text(
                'Analysis:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  analysisResult,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Raw data section
              Text(
                'Raw Data Scanned:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  rawData.isEmpty ? '(empty)' : rawData,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Expected format section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  expectedFormat,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _closeScanner();
            },
            child: const Text('Close Scanner'),
          ),
        ],
      ),
    );
  }

  void _showWrongTypeErrorDialog(String rawData, String processedData) {
    String message = '';
    if (QRCodeService.instance.isValidRLPTransaction(processedData)) {
      message = 'This QR code contains a transaction, not a private key. Use the "Sign Transaction" scanner instead.';
    } else {
      message = 'This QR code does not contain a valid private key format.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Wrong QR Code Type')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This scanner is specifically for importing private keys. For signing transactions, use the "Sign Transaction" option from the home screen.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _closeScanner();
            },
            child: const Text('Close Scanner'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialogAndClose(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Success'),
          ],
        ),
        content: SuccessCard(message: message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _closeScanner();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialogAndClose(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: WarningCard(
          message: message,
          isError: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _closeScanner();
            },
            child: const Text('Close'),
          ),
        ],
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

  void _closeScanner() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Private Key'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: !_hasPermission
          ? _buildPermissionDenied()
          : Column(
              children: [
                // Scanner status indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.key,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Scanning for Private Keys Only',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  flex: 3,
                  child: MobileScanner(
                    controller: _controller!,
                    onDetect: _handleDetection,
                  ),
                ),
                
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Point your camera at a private key QR code',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Only private keys will be accepted',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionDenied() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'Camera Permission Required',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'This app needs camera access to scan QR codes containing private keys.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _checkPermission,
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }
}
