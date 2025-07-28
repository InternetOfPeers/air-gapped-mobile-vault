import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/ethereum_transaction.dart';
import '../services/ethereum_transaction_service.dart';
import '../services/key_storage_service.dart';
import '../widgets/secure_card.dart';

class TransactionSigningScreen extends StatefulWidget {
  final String transactionData;

  const TransactionSigningScreen({
    super.key,
    required this.transactionData,
  });

  @override
  State<TransactionSigningScreen> createState() => _TransactionSigningScreenState();
}

class _TransactionSigningScreenState extends State<TransactionSigningScreen> {
  EthereumTransactionModel? _transaction;
  List<String> _availableKeys = [];
  String? _selectedKeyAlias;
  String? _signedTransaction;
  bool _isLoading = true;
  bool _isSigning = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      // Decode the transaction
      final transaction = EthereumTransactionService.instance.decodeTransaction(widget.transactionData);
      
      // Load available keys
      final keys = await KeyStorageService.instance.getStoredKeyAliases();
      
      if (mounted) {
        setState(() {
          _transaction = transaction;
          _availableKeys = keys;
          _isLoading = false;
        });

        if (_transaction == null) {
          _showDetailedTransactionErrorDialog(widget.transactionData);
          return;
        }

        if (_availableKeys.isEmpty) {
          _showErrorDialog('No private keys available. Please import a private key first.');
          return;
        }

        // Auto-select the first key if there's only one
        if (_availableKeys.length == 1) {
          setState(() {
            _selectedKeyAlias = _availableKeys.first;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showDetailedTransactionErrorDialog(widget.transactionData, error: e.toString());
      }
    }
  }

  Future<void> _signTransaction() async {
    if (_selectedKeyAlias == null || _transaction == null) return;

    setState(() {
      _isSigning = true;
    });

    try {
      final privateKey = await KeyStorageService.instance.getPrivateKey(_selectedKeyAlias!);
      if (privateKey == null) {
        _showErrorDialog('Failed to retrieve private key.');
        return;
      }

      final signedTx = await EthereumTransactionService.instance.signTransaction(_transaction!, privateKey);
      
      if (signedTx != null) {
        setState(() {
          _signedTransaction = signedTx;
        });
        _showSignedTransactionDialog();
      } else {
        _showErrorDialog('Failed to sign transaction. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Signing error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSigning = false;
        });
      }
    }
  }

  void _showSignedTransactionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Signed'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SuccessCard(
                message: 'Transaction has been signed successfully!',
                title: 'Success',
              ),
              const SizedBox(height: 16),
              SensitiveInfoCard(
                title: 'Signed Transaction',
                icon: Icons.check_circle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hash: ${EthereumTransactionService.instance.getTransactionHash(_signedTransaction!) ?? 'Unknown'}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Size: ${(_signedTransaction!.length / 2).toInt()} bytes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showQRCodeDialog();
            },
            child: const Text('Show QR Code'),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Signed Transaction QR Code',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: _signedTransaction!,
                  version: QrVersions.auto,
                  size: 300.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const WarningCard(
                message: 'Scan this QR code with another device to broadcast the transaction to the network.',
                title: 'Next Step',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context); // Return to previous screen
                      },
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: WarningCard(
          message: message,
          isError: true,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDetailedTransactionErrorDialog(String rawTransactionData, {String? error}) {
    String errorTitle = 'Transaction Decoding Failed';
    String errorMessage = 'Unable to decode the transaction data from the QR code.';
    
    // Analyze the transaction data
    String analysisResult = '';
    final cleanData = rawTransactionData.startsWith('0x') 
        ? rawTransactionData.substring(2) 
        : rawTransactionData;

    if (rawTransactionData.trim().isEmpty) {
      analysisResult = 'The transaction data is empty.';
    } else if (cleanData.length % 2 != 0) {
      analysisResult = 'Invalid hex format: must have even number of characters.';
    } else if (cleanData.length < 20) {
      analysisResult = 'Too short: minimum 20 characters expected for a transaction.';
    } else {
      try {
        BigInt.parse(cleanData, radix: 16);
        final firstByte = int.parse(cleanData.substring(0, 2), radix: 16);
        if (firstByte < 0xc0) {
          analysisResult = 'Invalid RLP format: transactions should start with list encoding (0xc0 or higher). Current first byte: 0x${firstByte.toRadixString(16).padLeft(2, '0')}';
        } else {
          analysisResult = 'Valid hex format with correct RLP prefix, but RLP decoding failed.';
        }
      } catch (e) {
        analysisResult = 'Invalid hexadecimal format: contains non-hex characters.';
      }
    }

    if (error != null) {
      analysisResult += '\n\nDetailed error: $error';
    }

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
            Expanded(child: Text(errorTitle)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage,
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
                'Transaction Data:',
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
                  rawTransactionData.isEmpty ? '(empty)' : rawTransactionData,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expected Format:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RLP-encoded Ethereum transaction:\n• Hexadecimal string starting with 0xc0 or higher\n• Contains encoded transaction fields (nonce, gasPrice, gasLimit, to, value, data)\n• Example: 0xf86c80851bf08eb00082520894...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('Back to Scanner'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Transaction'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transaction == null
              ? _buildErrorState()
              : _buildTransactionDetails(),
    );
  }

  Widget _buildErrorState() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: WarningCard(
          message: 'Unable to decode transaction. Please check the QR code format.',
          title: 'Invalid Transaction',
          isError: true,
        ),
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Warning
          const WarningCard(
            message: 'Carefully review all transaction details before signing. This action cannot be undone.',
            title: 'Security Warning',
          ),          
          const SizedBox(height: 24),
          
          // Transaction Overview
          Text(
            'Transaction Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
                    
          SensitiveInfoCard(
            title: 'Network',
            icon: Icons.language,
            child: Text(_transaction!.networkName),
          ),
          const SizedBox(height: 12),
          
          SensitiveInfoCard(
            title: 'Transaction Type',
            icon: Icons.receipt,
            child: Text(EthereumTransactionService.instance.getTransactionTypeString(_transaction!)),
          ),
          const SizedBox(height: 12),

          if (_transaction!.to != null) ...[
            SensitiveInfoCard(
              title: 'To Address',
              icon: Icons.account_balance_wallet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _transaction!.to!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          SensitiveInfoCard(
            title: 'Value',
            icon: Icons.monetization_on,
            child: Text(
              EthereumTransactionService.instance.formatWeiToEther(_transaction!.value ?? BigInt.zero),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          
          if (_transaction!.isLegacy && _transaction!.gasPrice != null) ...[
            SensitiveInfoCard(
              title: 'Gas Price',
              icon: Icons.local_gas_station,
              child: Text(
                EthereumTransactionService.instance.formatGasPrice(_transaction!.gasPrice!),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          if (!_transaction!.isLegacy && _transaction!.maxFeePerGas != null) ...[
            SensitiveInfoCard(
              title: 'Max Fee Per Gas',
              icon: Icons.local_gas_station,
              child: Text(
                EthereumTransactionService.instance.formatGasPrice(_transaction!.maxFeePerGas!),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!_transaction!.isLegacy && _transaction!.maxPriorityFeePerGas != null) ...[
            SensitiveInfoCard(
              title: 'Max Priority Fee',
              icon: Icons.priority_high,
              child: Text(
                EthereumTransactionService.instance.formatGasPrice(_transaction!.maxPriorityFeePerGas!),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (_transaction!.gasLimit != null) ...[
            SensitiveInfoCard(
              title: 'Gas Limit',
              icon: Icons.speed,
              child: Text(_transaction!.gasLimit!.toString()),
            ),
            const SizedBox(height: 12),
          ],

          if (_transaction!.estimatedFee != null) ...[
            SensitiveInfoCard(
              title: 'Estimated Fee',
              icon: Icons.payment,
              child: Text(
                EthereumTransactionService.instance.formatWeiToEther(_transaction!.estimatedFee!),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
          ], 

          if (_transaction!.hasData) ...[
            SensitiveInfoCard(
              title: 'Transaction Data',
              icon: Icons.data_object,
              child: Text('${_transaction!.data!.length} bytes of data'),
            ),
            const SizedBox(height: 12),
          ],
          
          const SizedBox(height: 12),
          
          // Key Selection
          Text(
            'Select Signing Key',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_availableKeys.isEmpty)
            const WarningCard(
              message: 'No private keys available. Please import a key first.',
              title: 'No Keys Available',
              isError: true,
            )
          else
            SensitiveInfoCard(
              title: 'Available Keys',
              icon: Icons.key,
              child: Column(
                children: [
                  ..._availableKeys.map((alias) => RadioListTile<String>(
                    title: Text(alias),
                    value: alias,
                    groupValue: _selectedKeyAlias,
                    onChanged: (value) {
                      setState(() {
                        _selectedKeyAlias = value;
                      });
                    },
                  )),
                ],
              ),
            ),
          const SizedBox(height: 32),
          
          // Sign Button
          if (_selectedKeyAlias != null && _signedTransaction == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSigning ? null : _signTransaction,
                child: _isSigning
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Signing...'),
                        ],
                      )
                    : const Text('Sign Transaction'),
              ),
            ),
          
          if (_signedTransaction != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showQRCodeDialog,
                child: const Text('Show QR Code'),
              ),
            ),
        ],
      ),
    );
  }
}
