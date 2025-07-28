import 'dart:typed_data';

/// Model representing an Ethereum transaction
class EthereumTransactionModel {
  final BigInt? nonce;
  final BigInt? gasPrice;
  final BigInt? gasLimit;
  final String? to;
  final BigInt? value;
  final Uint8List? data;
  final BigInt? chainId;
  final bool isLegacy;
  final String? rawData; // Store original RLP hex data

  // EIP-1559 fields (for Type 2 transactions)
  final BigInt? maxFeePerGas;
  final BigInt? maxPriorityFeePerGas;

  // Transaction type (0 = Legacy, 1 = EIP-2930, 2 = EIP-1559)
  final int? transactionType;

  // Access list for EIP-2930 and EIP-1559 transactions
  final List<Map<String, dynamic>>? accessList;

  const EthereumTransactionModel({
    this.nonce,
    this.gasPrice,
    this.gasLimit,
    this.to,
    this.value,
    this.data,
    this.chainId,
    this.isLegacy = true,
    this.maxFeePerGas,
    this.maxPriorityFeePerGas,
    this.rawData,
    this.transactionType,
    this.accessList,
  });

  /// Create a copy of the transaction with modified fields
  EthereumTransactionModel copyWith({
    BigInt? nonce,
    BigInt? gasPrice,
    BigInt? gasLimit,
    String? to,
    BigInt? value,
    Uint8List? data,
    BigInt? chainId,
    bool? isLegacy,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
    String? rawData,
    int? transactionType,
    List<Map<String, dynamic>>? accessList,
  }) {
    return EthereumTransactionModel(
      nonce: nonce ?? this.nonce,
      gasPrice: gasPrice ?? this.gasPrice,
      gasLimit: gasLimit ?? this.gasLimit,
      to: to ?? this.to,
      value: value ?? this.value,
      data: data ?? this.data,
      chainId: chainId ?? this.chainId,
      isLegacy: isLegacy ?? this.isLegacy,
      maxFeePerGas: maxFeePerGas ?? this.maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas ?? this.maxPriorityFeePerGas,
      rawData: rawData ?? this.rawData,
      transactionType: transactionType ?? this.transactionType,
      accessList: accessList ?? this.accessList,
    );
  }

  /// Check if this is a contract creation transaction
  bool get isContractCreation => to == null || to!.isEmpty;

  /// Check if this transaction has data
  bool get hasData => data != null && data!.isNotEmpty;

  /// Get the network name from chain ID
  String get networkName {
    switch (chainId?.toInt()) {
      case 1:
        return 'Ethereum Mainnet';
      case 3:
        return 'Ropsten Testnet';
      case 4:
        return 'Rinkeby Testnet';
      case 5:
        return 'Goerli Testnet';
      case 56:
        return 'BSC Mainnet';
      case 97:
        return 'BSC Testnet';
      case 137:
        return 'Polygon Mainnet';
      case 295:
        return 'Hedera Mainnet';
      case 296:
        return 'Hedera Testnet';
      case 297:
        return 'Hedera Previewnet';
      case 80001:
        return 'Polygon Mumbai';
      case 11155111:
        return 'Sepolia Testnet';
      default:
        return 'Unknown Network (${chainId?.toString() ?? 'No Chain ID'})';
    }
  }

  /// Get transaction type string
  String get transactionTypeString {
    if (isContractCreation) {
      return 'Contract Creation';
    } else if (hasData) {
      return 'Contract Interaction or Transfer with data';
    } else {
      return 'Transfer';
    }
  }

  /// Calculate estimated transaction fee
  BigInt? get estimatedFee {
    if (gasLimit == null) return null;
    
    if (isLegacy) {
      return gasPrice != null ? gasLimit! * gasPrice! : null;
    } else {
      return maxFeePerGas != null ? gasLimit! * maxFeePerGas! : null;
    }
  }

  @override
  String toString() {
    return 'EthereumTransaction{\n'
        '  nonce: $nonce,\n'
        '  gasPrice: $gasPrice,\n'
        '  gasLimit: $gasLimit,\n'
        '  to: $to,\n'
        '  value: $value,\n'
        '  data: ${data?.length} bytes,\n'
        '  chainId: $chainId,\n'
        '  isLegacy: $isLegacy,\n'
        '  transactionType: $transactionType,\n'
        '  maxFeePerGas: $maxFeePerGas,\n'
        '  maxPriorityFeePerGas: $maxPriorityFeePerGas,\n'
        '  accessList: ${accessList?.length} entries\n'
        '}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EthereumTransactionModel) return false;
    
    return nonce == other.nonce &&
        gasPrice == other.gasPrice &&
        gasLimit == other.gasLimit &&
        to == other.to &&
        value == other.value &&
        _uint8ListEquals(data, other.data) &&
        chainId == other.chainId &&
        isLegacy == other.isLegacy &&
        transactionType == other.transactionType &&
        maxFeePerGas == other.maxFeePerGas &&
        maxPriorityFeePerGas == other.maxPriorityFeePerGas &&
        _listEquals(accessList, other.accessList);
  }

  @override
  int get hashCode {
    return Object.hash(
      nonce,
      gasPrice,
      gasLimit,
      to,
      value,
      data?.hashCode,
      chainId,
      isLegacy,
      transactionType,
      maxFeePerGas,
      maxPriorityFeePerGas,
      accessList?.hashCode,
    );
  }

  /// Helper method to compare Uint8List
  bool _uint8ListEquals(Uint8List? a, Uint8List? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Helper method to compare List<Map<String, dynamic>>
  bool _listEquals(List<Map<String, dynamic>>? a, List<Map<String, dynamic>>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    
    for (int i = 0; i < a.length; i++) {
      if (a[i].toString() != b[i].toString()) return false;
    }
    return true;
  }
}
