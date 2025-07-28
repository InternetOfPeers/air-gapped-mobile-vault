import 'dart:typed_data';
import 'package:web3dart/web3dart.dart';
import 'package:convert/convert.dart';
import '../models/ethereum_transaction.dart';

/// Clean implementation of Ethereum transaction RLP encoding/decoding and signing
class EthereumTransactionService {
  static final EthereumTransactionService _instance = EthereumTransactionService._internal();
  static EthereumTransactionService get instance => _instance;
  
  EthereumTransactionService._internal();

  /// Decode an RLP-encoded transaction from hex string
  EthereumTransactionModel? decodeTransaction(String rlpHex) {
    try {
      // Remove 0x prefix if present
      final cleanHex = rlpHex.startsWith('0x') ? rlpHex.substring(2) : rlpHex;
      
      // Decode hex to bytes
      final bytes = hex.decode(cleanHex);
      
      // Check if this is a typed transaction (EIP-2718)
      if (bytes.isNotEmpty && bytes[0] <= 0x7f) {
        return _decodeTypedTransaction(bytes, rlpHex);
      } else {
        return _decodeLegacyTransaction(bytes, rlpHex);
      }
    } catch (e) {
      print('Error decoding transaction: $e');
      return null;
    }
  }

  /// Encode a transaction to RLP hex string
  String? encodeTransaction(EthereumTransactionModel transaction) {
    try {
      if (transaction.isLegacy) {
        return _encodeLegacyTransaction(transaction);
      } else {
        return _encodeTypedTransaction(transaction);
      }
    } catch (e) {
      print('Error encoding transaction: $e');
      return null;
    }
  }

  /// Sign a transaction with the provided private key
  Future<String?> signTransaction(EthereumTransactionModel transaction, String privateKeyHex) async {
    try {
      final cleanPrivateKey = privateKeyHex.startsWith('0x') 
          ? privateKeyHex.substring(2) 
          : privateKeyHex;
      
      // Create credentials from private key
      final credentials = EthPrivateKey.fromHex(cleanPrivateKey);
      
      // Prepare the transaction for signing (RLP encode the unsigned transaction)
      List<dynamic> txFields;
      
      if (transaction.isLegacy) {
        // Legacy transaction fields: [nonce, gasPrice, gasLimit, to, value, data, chainId, 0, 0]
        txFields = [
          _encodeInt(transaction.nonce ?? BigInt.zero),
          _encodeInt(transaction.gasPrice ?? BigInt.zero),
          _encodeInt(transaction.gasLimit ?? BigInt.zero),
          _encodeAddress(transaction.to),
          _encodeInt(transaction.value ?? BigInt.zero),
          _encodeData(transaction.data),
          _encodeInt(transaction.chainId ?? BigInt.one),
          [], // v placeholder
          [], // r placeholder
        ];
        
        // RLP encode the transaction for signing
        final encodedTx = _rlpEncode(txFields);
        
        // Sign the encoded transaction
        final signature = credentials.signToEcSignature(
          Uint8List.fromList(encodedTx),
          chainId: transaction.chainId?.toInt() ?? 1,
          isEIP1559: false,
        );
        
        // Replace placeholders with actual signature values
        final signedFields = [
          _encodeInt(transaction.nonce ?? BigInt.zero),
          _encodeInt(transaction.gasPrice ?? BigInt.zero),
          _encodeInt(transaction.gasLimit ?? BigInt.zero),
          _encodeAddress(transaction.to),
          _encodeInt(transaction.value ?? BigInt.zero),
          _encodeData(transaction.data),
          _encodeInt(BigInt.from(signature.v)),
          _encodeInt(signature.r),
          _encodeInt(signature.s),
        ];
        
        final signedTx = _rlpEncode(signedFields);
        return '0x${hex.encode(signedTx)}';
      } else {
        // EIP-1559 transaction
        final txType = transaction.transactionType ?? 2;
        
        if (txType == 2) {
          // EIP-1559 fields: [chainId, nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to, value, data, accessList]
          txFields = [
            _encodeInt(transaction.chainId ?? BigInt.one),
            _encodeInt(transaction.nonce ?? BigInt.zero),
            _encodeInt(transaction.maxPriorityFeePerGas ?? BigInt.zero),
            _encodeInt(transaction.maxFeePerGas ?? BigInt.zero),
            _encodeInt(transaction.gasLimit ?? BigInt.zero),
            _encodeAddress(transaction.to),
            _encodeInt(transaction.value ?? BigInt.zero),
            _encodeData(transaction.data),
            _encodeAccessList(transaction.accessList ?? []),
          ];
        } else {
          // EIP-2930 fields: [chainId, nonce, gasPrice, gasLimit, to, value, data, accessList]
          txFields = [
            _encodeInt(transaction.chainId ?? BigInt.one),
            _encodeInt(transaction.nonce ?? BigInt.zero),
            _encodeInt(transaction.gasPrice ?? BigInt.zero),
            _encodeInt(transaction.gasLimit ?? BigInt.zero),
            _encodeAddress(transaction.to),
            _encodeInt(transaction.value ?? BigInt.zero),
            _encodeData(transaction.data),
            _encodeAccessList(transaction.accessList ?? []),
          ];
        }
        
        // RLP encode the transaction data
        final encodedTxData = _rlpEncode(txFields);
        
        // Prepend transaction type for signing
        final txForSigning = Uint8List.fromList([txType, ...encodedTxData]);
        
        // Sign the transaction
        final signature = credentials.signToEcSignature(
          txForSigning,
          chainId: transaction.chainId?.toInt() ?? 1,
          isEIP1559: txType == 2,
        );
        
        // Add signature to the fields
        txFields.add(_encodeInt(BigInt.from(signature.v))); // y-parity for EIP-1559
        txFields.add(_encodeInt(signature.r));
        txFields.add(_encodeInt(signature.s));
        
        // Re-encode with signature
        final signedTxData = _rlpEncode(txFields);
        final signedTx = Uint8List.fromList([txType, ...signedTxData]);
        
        return '0x${hex.encode(signedTx)}';
      }
    } catch (e) {
      print('Error signing transaction: $e');
      return null;
    }
  }

  /// Get address from private key
  String? getAddressFromPrivateKey(String privateKeyHex) {
    try {
      final cleanPrivateKey = privateKeyHex.startsWith('0x') 
          ? privateKeyHex.substring(2) 
          : privateKeyHex;
      
      final credentials = EthPrivateKey.fromHex(cleanPrivateKey);
      final address = credentials.address.toString();
      return address.startsWith('0x') ? address : '0x$address';
    } catch (e) {
      print('Error getting address from private key: $e');
      return null;
    }
  }

  // PRIVATE METHODS

  /// Decode legacy transaction (type 0)
  EthereumTransactionModel? _decodeLegacyTransaction(List<int> bytes, String originalHex) {
    try {
      final decoded = _rlpDecode(bytes);
      if (decoded is! List || decoded.length < 6) {
        throw Exception('Invalid legacy transaction format');
      }
      
      return EthereumTransactionModel(
        nonce: _decodeInt(decoded[0]),
        gasPrice: _decodeInt(decoded[1]),
        gasLimit: _decodeInt(decoded[2]),
        to: _decodeAddress(decoded[3]),
        value: _decodeInt(decoded[4]),
        data: _decodeData(decoded[5]),
        chainId: decoded.length >= 9 ? _decodeInt(decoded[6]) : null,
        isLegacy: true,
        transactionType: 0,
        rawData: originalHex,
        accessList: [],
      );
    } catch (e) {
      print('Error decoding legacy transaction: $e');
      return null;
    }
  }

  /// Decode typed transaction (EIP-2718)
  EthereumTransactionModel? _decodeTypedTransaction(List<int> bytes, String originalHex) {
    try {
      if (bytes.isEmpty) return null;
      
      final transactionType = bytes[0];
      final payload = bytes.sublist(1);
      final decoded = _rlpDecode(payload);
      
      if (decoded is! List) {
        throw Exception('Invalid typed transaction format');
      }
      
      switch (transactionType) {
        case 0x01: // EIP-2930 (Access List Transaction)
          return _decodeAccessListTransaction(decoded, originalHex, transactionType);
        case 0x02: // EIP-1559 (Dynamic Fee Transaction)
          return _decodeDynamicFeeTransaction(decoded, originalHex, transactionType);
        default:
          throw Exception('Unsupported transaction type: 0x${transactionType.toRadixString(16)}');
      }
    } catch (e) {
      print('Error decoding typed transaction: $e');
      return null;
    }
  }

  /// Decode EIP-2930 Access List transaction
  EthereumTransactionModel? _decodeAccessListTransaction(List decoded, String originalHex, int txType) {
    try {
      if (decoded.length < 8) {
        throw Exception('Invalid access list transaction format');
      }
      
      return EthereumTransactionModel(
        chainId: _decodeInt(decoded[0]),
        nonce: _decodeInt(decoded[1]),
        gasPrice: _decodeInt(decoded[2]),
        gasLimit: _decodeInt(decoded[3]),
        to: _decodeAddress(decoded[4]),
        value: _decodeInt(decoded[5]),
        data: _decodeData(decoded[6]),
        accessList: _decodeAccessList(decoded[7]),
        isLegacy: false,
        transactionType: txType,
        rawData: originalHex,
      );
    } catch (e) {
      print('Error decoding access list transaction: $e');
      return null;
    }
  }

  /// Decode EIP-1559 Dynamic Fee transaction
  EthereumTransactionModel? _decodeDynamicFeeTransaction(List decoded, String originalHex, int txType) {
    try {
      if (decoded.length < 9) {
        throw Exception('Invalid dynamic fee transaction format');
      }
      
      return EthereumTransactionModel(
        chainId: _decodeInt(decoded[0]),
        nonce: _decodeInt(decoded[1]),
        maxPriorityFeePerGas: _decodeInt(decoded[2]),
        maxFeePerGas: _decodeInt(decoded[3]),
        gasLimit: _decodeInt(decoded[4]),
        to: _decodeAddress(decoded[5]),
        value: _decodeInt(decoded[6]),
        data: _decodeData(decoded[7]),
        accessList: _decodeAccessList(decoded[8]),
        isLegacy: false,
        transactionType: txType,
        rawData: originalHex,
      );
    } catch (e) {
      print('Error decoding dynamic fee transaction: $e');
      return null;
    }
  }

  /// Encode legacy transaction
  String? _encodeLegacyTransaction(EthereumTransactionModel transaction) {
    try {
      final fields = [
        _encodeInt(transaction.nonce ?? BigInt.zero),
        _encodeInt(transaction.gasPrice ?? BigInt.zero),
        _encodeInt(transaction.gasLimit ?? BigInt.zero),
        _encodeAddress(transaction.to),
        _encodeInt(transaction.value ?? BigInt.zero),
        _encodeData(transaction.data),
        _encodeInt(transaction.chainId ?? BigInt.zero),
        _encodeInt(BigInt.zero), // v (empty for unsigned)
        _encodeInt(BigInt.zero), // r (empty for unsigned)
      ];
      
      final encoded = _rlpEncode(fields);
      return '0x${hex.encode(encoded)}';
    } catch (e) {
      print('Error encoding legacy transaction: $e');
      return null;
    }
  }

  /// Encode typed transaction
  String? _encodeTypedTransaction(EthereumTransactionModel transaction) {
    try {
      final txType = transaction.transactionType ?? 2;
      List<dynamic> fields;
      
      if (txType == 1) {
        // EIP-2930
        fields = [
          _encodeInt(transaction.chainId ?? BigInt.zero),
          _encodeInt(transaction.nonce ?? BigInt.zero),
          _encodeInt(transaction.gasPrice ?? BigInt.zero),
          _encodeInt(transaction.gasLimit ?? BigInt.zero),
          _encodeAddress(transaction.to),
          _encodeInt(transaction.value ?? BigInt.zero),
          _encodeData(transaction.data),
          _encodeAccessList(transaction.accessList ?? []),
        ];
      } else {
        // EIP-1559
        fields = [
          _encodeInt(transaction.chainId ?? BigInt.zero),
          _encodeInt(transaction.nonce ?? BigInt.zero),
          _encodeInt(transaction.maxPriorityFeePerGas ?? BigInt.zero),
          _encodeInt(transaction.maxFeePerGas ?? BigInt.zero),
          _encodeInt(transaction.gasLimit ?? BigInt.zero),
          _encodeAddress(transaction.to),
          _encodeInt(transaction.value ?? BigInt.zero),
          _encodeData(transaction.data),
          _encodeAccessList(transaction.accessList ?? []),
        ];
      }
      
      final encoded = _rlpEncode(fields);
      final result = Uint8List.fromList([txType, ...encoded]);
      return '0x${hex.encode(result)}';
    } catch (e) {
      print('Error encoding typed transaction: $e');
      return null;
    }
  }

    // PRIVATE METHODS

  // RLP ENCODING/DECODING HELPERS

  /// Simple RLP decode implementation
  dynamic _rlpDecode(List<int> input) {
    if (input.isEmpty) return [];
    
    final byte = input[0];
    
    if (byte <= 0x7f) {
      // Single byte
      return [byte];
    } else if (byte <= 0xb7) {
      // Short string
      final length = byte - 0x80;
      if (length == 0) return [];
      return input.sublist(1, 1 + length);
    } else if (byte <= 0xbf) {
      // Long string
      final lengthOfLength = byte - 0xb7;
      var length = 0;
      for (int i = 0; i < lengthOfLength; i++) {
        length = (length << 8) + input[1 + i];
      }
      return input.sublist(1 + lengthOfLength, 1 + lengthOfLength + length);
    } else if (byte <= 0xf7) {
      // Short list
      final length = byte - 0xc0;
      if (length == 0) return [];
      return _rlpDecodeList(input.sublist(1, 1 + length));
    } else {
      // Long list
      final lengthOfLength = byte - 0xf7;
      var length = 0;
      for (int i = 0; i < lengthOfLength; i++) {
        length = (length << 8) + input[1 + i];
      }
      return _rlpDecodeList(input.sublist(1 + lengthOfLength, 1 + lengthOfLength + length));
    }
  }

  /// Decode RLP list
  List<dynamic> _rlpDecodeList(List<int> input) {
    final result = <dynamic>[];
    var offset = 0;
    
    while (offset < input.length) {
      final itemData = _rlpDecode(input.sublist(offset));
      result.add(itemData);
      
      // Calculate offset for next item
      final byte = input[offset];
      if (byte <= 0x7f) {
        offset += 1;
      } else if (byte <= 0xb7) {
        offset += 1 + (byte - 0x80);
      } else if (byte <= 0xbf) {
        final lengthOfLength = byte - 0xb7;
        var length = 0;
        for (int i = 0; i < lengthOfLength; i++) {
          length = (length << 8) + input[offset + 1 + i];
        }
        offset += 1 + lengthOfLength + length;
      } else if (byte <= 0xf7) {
        offset += 1 + (byte - 0xc0);
      } else {
        final lengthOfLength = byte - 0xf7;
        var length = 0;
        for (int i = 0; i < lengthOfLength; i++) {
          length = (length << 8) + input[offset + 1 + i];
        }
        offset += 1 + lengthOfLength + length;
      }
    }
    
    return result;
  }

  /// Simple RLP encode implementation
  List<int> _rlpEncode(dynamic input) {
    if (input is List<int>) {
      // Encode byte array
      if (input.length == 1 && input[0] <= 0x7f) {
        return input;
      } else if (input.length <= 55) {
        return [0x80 + input.length, ...input];
      } else {
        final lengthBytes = _encodeLength(input.length);
        return [0xb7 + lengthBytes.length, ...lengthBytes, ...input];
      }
    } else if (input is List) {
      // Encode list of items (each item is also a List<int>)
      final encoded = <int>[];
      for (final item in input) {
        encoded.addAll(_rlpEncode(item));
      }
      
      if (encoded.length <= 55) {
        return [0xc0 + encoded.length, ...encoded];
      } else {
        final lengthBytes = _encodeLength(encoded.length);
        return [0xf7 + lengthBytes.length, ...lengthBytes, ...encoded];
      }
    } else {
      throw ArgumentError('Invalid input type for RLP encoding: ${input.runtimeType}');
    }
  }

  /// Encode length as bytes
  List<int> _encodeLength(int length) {
    if (length == 0) return [];
    
    final result = <int>[];
    while (length > 0) {
      result.insert(0, length & 0xff);
      length >>= 8;
    }
    return result;
  }
  
  // UTILITY METHODS FOR UI
  
  /// Get transaction hash from signed transaction (placeholder implementation)
  // TODO: Implement proper transaction hash calculation
  String? getTransactionHash(String signedTxHex) {
    try {
      final cleanHex = signedTxHex.startsWith('0x') ? signedTxHex.substring(2) : signedTxHex;
      final bytes = hex.decode(cleanHex);
      
      // Simple hash implementation - in production use proper Keccak256
      return '0x${hex.encode(bytes.take(32).toList())}';
    } catch (e) {
      return null;
    }
  }

  /// Get transaction type string for display
  String getTransactionTypeString(EthereumTransactionModel transaction) {
    return transaction.transactionTypeString;
  }

  /// Get a shortened version of an address for display
  String shortenAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  /// Format Wei to Ether string for display
  String formatWeiToEther(BigInt wei) {
    if (wei == BigInt.zero) return '0 ETH';
    
    // Convert wei to ether with precise decimal handling
    // 1 ETH = 10^18 wei
    final etherString = _formatBigIntWithDecimals(wei, 18);
    return '$etherString ETH';
  }

  /// Format gas price for display (Wei to Gwei)
  String formatGasPrice(BigInt gasPrice) {
    if (gasPrice == BigInt.zero) return '0 Gwei';
    
    // Convert wei to gwei with precise decimal handling
    // 1 Gwei = 10^9 wei
    final gweiString = _formatBigIntWithDecimals(gasPrice, 9);
    return '$gweiString Gwei';
  }

  /// Helper method to format BigInt with decimal places
  String _formatBigIntWithDecimals(BigInt value, int decimals) {
    if (value == BigInt.zero) return '0';
    
    final divisor = BigInt.from(10).pow(decimals);
    final integerPart = value ~/ divisor;
    final fractionalPart = value % divisor;
    
    if (fractionalPart == BigInt.zero) {
      return integerPart.toString();
    }
    
    // Convert fractional part to string with leading zeros
    final fractionalString = fractionalPart.toString().padLeft(decimals, '0');
    
    // Remove trailing zeros from fractional part
    final trimmedFractional = fractionalString.replaceAll(RegExp(r'0+$'), '');
    
    if (trimmedFractional.isEmpty) {
      return integerPart.toString();
    }
    
    return '${integerPart}.${trimmedFractional}';
  }

  // FIELD ENCODING/DECODING HELPERS

  /// Decode integer from RLP bytes
  BigInt _decodeInt(dynamic value) {
    if (value == null) return BigInt.zero;
    if (value is List<int>) {
      if (value.isEmpty) return BigInt.zero;
      
      BigInt result = BigInt.zero;
      for (int byte in value) {
        result = (result << 8) + BigInt.from(byte);
      }
      return result;
    }
    return BigInt.zero;
  }

  /// Decode address from RLP bytes
  String? _decodeAddress(dynamic value) {
    if (value == null) return null;
    if (value is List<int>) {
      if (value.isEmpty) return null;
      return '0x${hex.encode(value)}';
    }
    return null;
  }

  /// Decode data from RLP bytes
  Uint8List? _decodeData(dynamic value) {
    if (value == null) return null;
    if (value is List<int>) {
      if (value.isEmpty) return null;
      return Uint8List.fromList(value);
    }
    return null;
  }

  /// Decode access list from RLP
  List<Map<String, dynamic>> _decodeAccessList(dynamic value) {
    if (value == null || value is! List) return [];
    
    final result = <Map<String, dynamic>>[];
    for (final item in value) {
      if (item is List && item.length >= 2) {
        final address = _decodeAddress(item[0]);
        final storageKeys = <String>[];
        
        if (item[1] is List) {
          for (final key in item[1]) {
            final keyStr = _decodeAddress(key);
            if (keyStr != null) {
              storageKeys.add(keyStr);
            }
          }
        }
        
        if (address != null) {
          result.add({
            'address': address,
            'storageKeys': storageKeys,
          });
        }
      }
    }
    
    return result;
  }

  /// Encode integer to RLP bytes
  List<int> _encodeInt(BigInt value) {
    if (value == BigInt.zero) return [];
    
    final bytes = <int>[];
    var temp = value;
    while (temp > BigInt.zero) {
      bytes.insert(0, temp.remainder(BigInt.from(256)).toInt());
      temp = temp >> 8;
    }
    return bytes;
  }

  /// Encode address to RLP bytes
  List<int> _encodeAddress(String? address) {
    if (address == null || address.isEmpty) return [];
    
    final cleanAddress = address.startsWith('0x') ? address.substring(2) : address;
    return hex.decode(cleanAddress);
  }

  /// Encode data to RLP bytes
  List<int> _encodeData(Uint8List? data) {
    if (data == null || data.isEmpty) return [];
    return data.toList();
  }

  /// Encode access list to RLP
  List<dynamic> _encodeAccessList(List<Map<String, dynamic>> accessList) {
    final result = <List<dynamic>>[];
    
    for (final entry in accessList) {
      final address = entry['address'] as String?;
      final storageKeys = entry['storageKeys'] as List<String>?;
      
      if (address != null) {
        final encodedKeys = <List<int>>[];
        if (storageKeys != null) {
          for (final key in storageKeys) {
            encodedKeys.add(_encodeAddress(key));
          }
        }
        
        result.add([
          _encodeAddress(address),
          encodedKeys,
        ]);
      }
    }
    
    return result;
  }
}
