import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ethereum_transaction_service.dart';

/// Service for handling QR code scanning and generation
class QRCodeService {
  static final QRCodeService _instance = QRCodeService._internal();
  static QRCodeService get instance => _instance;
  
  QRCodeService._internal();

  /// Request camera permission for QR code scanning
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  /// Validate if a string is a valid private key
  bool isValidPrivateKey(String data) {
    // Remove 0x prefix if present
    final cleanData = data.startsWith('0x') ? data.substring(2) : data;
    
    // Check if it's a 64-character hex string (256-bit key)
    if (cleanData.length != 64) return false;
    
    try {
      final keyInt = BigInt.parse(cleanData, radix: 16);
      // Check if the key is in valid range (greater than 0 and less than secp256k1 curve order)
      final curveOrder = BigInt.parse('fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141', radix: 16);
      return keyInt > BigInt.zero && keyInt < curveOrder;
    } catch (e) {
      return false;
    }
  }

  /// Get detailed validation info for a private key
  String getPrivateKeyValidationInfo(String data) {
    final cleanData = data.startsWith('0x') ? data.substring(2) : data;
    
    if (cleanData.isEmpty) {
      return 'Empty data';
    }
    
    if (cleanData.length != 64) {
      return 'Invalid length: ${cleanData.length} characters (expected 64)';
    }
    
    try {
      final keyInt = BigInt.parse(cleanData, radix: 16);
      final curveOrder = BigInt.parse('fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141', radix: 16);
      
      if (keyInt == BigInt.zero) {
        return 'Invalid: private key cannot be zero';
      }
      
      if (keyInt >= curveOrder) {
        return 'Invalid: private key exceeds secp256k1 curve order';
      }
      
      return 'Valid private key format';
    } catch (e) {
      return 'Invalid hexadecimal format';
    }
  }

  /// Validate if a string is a valid RLP-encoded transaction
  bool isValidRLPTransaction(String data) {
    final transaction = EthereumTransactionService.instance.decodeTransaction(data);
    return transaction != null;
  }

  /// Get detailed validation info for an RLP transaction
  String getRLPTransactionValidationInfo(String data) {
    final cleanData = data.startsWith('0x') ? data.substring(2) : data;
    
    if (cleanData.isEmpty) {
      return 'Empty data';
    }
    
    if (cleanData.length % 2 != 0) {
      return 'Invalid: hex string must have even number of characters';
    }
    
    if (cleanData.length < 20) {
      return 'Too short: minimum 20 characters expected for transaction';
    }
    
    try {
      BigInt.parse(cleanData, radix: 16);
      
      // Use the Ethereum service to validate the transaction
      final transaction = EthereumTransactionService.instance.decodeTransaction(data);
      if (transaction != null) {
        return 'Valid RLP transaction format';
      } else {
        return 'Invalid RLP format: unable to decode transaction';
      }
    } catch (e) {
      return 'Invalid hexadecimal format';
    }
  }

  /// Determine the type of QR code data
  QRDataType getQRDataType(String data) {
    if (isValidPrivateKey(data)) {
      return QRDataType.privateKey;
    } else if (isValidRLPTransaction(data)) {
      return QRDataType.transaction;
    } else {
      return QRDataType.unknown;
    }
  }

  /// Clean and validate QR code data
  String? processQRData(String rawData) {
    // Trim whitespace
    final trimmed = rawData.trim();
    
    // Remove common prefixes/suffixes that might be added by QR generators
    String cleaned = trimmed;
    
    // Remove ethereum: prefix if present
    if (cleaned.toLowerCase().startsWith('ethereum:')) {
      cleaned = cleaned.substring(9);
    }
    
    // Validate the cleaned data
    final dataType = getQRDataType(cleaned);
    if (dataType == QRDataType.unknown) {
      return null;
    }
    
    return cleaned;
  }

  /// Generate QR code data for a private key (with warning)
  String generatePrivateKeyQRData(String privateKey) {
    // Ensure 0x prefix for consistency
    return privateKey.startsWith('0x') ? privateKey : '0x$privateKey';
  }

  /// Generate QR code data for a signed transaction
  String generateSignedTransactionQRData(String signedTx) {
    // Ensure 0x prefix for consistency
    return signedTx.startsWith('0x') ? signedTx : '0x$signedTx';
  }

  /// Get appropriate scanner configuration for the platform
  void Function(BarcodeCapture) getOnDetectCallback(
    Function(String) onScanned,
    Function(String) onError,
  ) {
    return (BarcodeCapture capture) {
      final List<Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        if (barcode.rawValue != null) {
          final processedData = processQRData(barcode.rawValue!);
          if (processedData != null) {
            onScanned(processedData);
            return;
          } else {
            onError('Invalid QR code format');
            return;
          }
        }
      }
    };
  }

  /// Get recommended mobile scanner widget
  static Widget getMobileScanner({
    required MobileScannerController controller,
    required void Function(BarcodeCapture) onDetect,
  }) {
    return MobileScanner(
      controller: controller,
      onDetect: onDetect,
    );
  }
}

/// Enum for different types of QR code data
enum QRDataType {
  privateKey,
  transaction,
  unknown,
}

/// Extension to get human-readable names for QR data types
extension QRDataTypeExtension on QRDataType {
  String get displayName {
    switch (this) {
      case QRDataType.privateKey:
        return 'Private Key';
      case QRDataType.transaction:
        return 'Transaction';
      case QRDataType.unknown:
        return 'Unknown';
    }
  }
}
