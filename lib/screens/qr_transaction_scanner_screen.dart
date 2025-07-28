import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_code_service.dart';
import '../widgets/secure_card.dart';
import 'transaction_signing_screen.dart';

class QRTransactionScannerScreen extends StatefulWidget {
  const QRTransactionScannerScreen({super.key});

  @override
  State<QRTransactionScannerScreen> createState() => _QRTransactionScannerScreenState();
}

class _QRTransactionScannerScreenState extends State<QRTransactionScannerScreen> {
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

    // Check if it's specifically a transaction
    if (!QRCodeService.instance.isValidRLPTransaction(processedData)) {
      _showWrongTypeErrorDialog(data, processedData);
      return;
    }

    _showTransactionConfirmationDialog(processedData);
  }

  void _showTransactionConfirmationDialog(String transactionData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.receipt,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Transaction Detected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'An Ethereum transaction has been detected. Would you like to review and sign it?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Transaction data preview:\n${transactionData.substring(0, 50)}...',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToTransactionSigning(transactionData);
            },
            child: const Text('Review Transaction'),
          ),
        ],
      ),
    );
  }

  void _navigateToTransactionSigning(String transactionData) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionSigningScreen(
          transactionData: transactionData,
        ),
      ),
    );
  }

  void _showDetailedErrorDialog(String rawData) {
    String analysisResult = '';
    final transactionInfo = QRCodeService.instance.getRLPTransactionValidationInfo(rawData);
    analysisResult = 'Transaction Analysis: $transactionInfo';

    String expectedFormat = '''Expected Format:

📄 RLP-encoded Transaction:
• Variable-length hexadecimal string
• Must start with RLP list encoding (0xc0 or higher)
• Represents a serialized Ethereum transaction
• Example: 0xf86c80851bf08eb00082520894a0b86a96c6b2b0c76a32bf3c8b5e5e5e5e5e5e5e8890de0b6b3a764000080''';

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
            const Expanded(child: Text('Invalid Transaction QR Code')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The scanned QR code does not contain a valid RLP-encoded transaction.',
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
    if (QRCodeService.instance.isValidPrivateKey(processedData)) {
      message = 'This QR code contains a private key, not a transaction. Use the "Import Private Key" scanner instead.';
    } else {
      message = 'This QR code does not contain a valid transaction format.';
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
                'This scanner is specifically for transactions. For importing private keys, use the "Import Private Key" option from the key management screen.',
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

  void _closeScanner() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Transaction'),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
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
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Scanning for Transactions Only',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
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
                          'Point your camera at a transaction QR code',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Only RLP-encoded transactions will be accepted',
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
            'This app needs camera access to scan QR codes containing transactions.',
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
