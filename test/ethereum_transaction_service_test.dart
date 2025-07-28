import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:convert/convert.dart';
import 'package:air_gapped_vault/services/ethereum_transaction_service.dart';
import 'package:air_gapped_vault/models/ethereum_transaction.dart';

void main() {
  group('EthereumTransactionService', () {
    late EthereumTransactionService service;

    setUp(() {
      service = EthereumTransactionService.instance;
    });

    group('RLP Decoding Tests', () {
      test('should decode legacy transaction (type 0)', () {
        // Given: Legacy transaction from your example
        const rlpHex = '0xdf0d0c82520894d8da6bf26964af9d7eed9e03e53415d37aa960450b800e8080';
        
        // When: Decoding the transaction
        final result = service.decodeTransaction(rlpHex);
        
        // Then: Should match expected values
        expect(result, isNotNull);
        expect(result!.transactionType, equals(0));
        expect(result.isLegacy, isTrue);
        expect(result.to?.toLowerCase(), equals('0xd8da6bf26964af9d7eed9e03e53415d37aa96045'));
        expect(result.value, equals(BigInt.from(11)));
        expect(result.gasLimit, equals(BigInt.from(21000)));
        expect(result.gasPrice, equals(BigInt.from(12)));
        expect(result.nonce, equals(BigInt.from(13)));
        expect(result.chainId, equals(BigInt.from(14)));
        expect(result.data, isNull);
      });

      test('should decode EIP-2930 transaction (type 1) without access list', () {
        // Given: EIP-2930 transaction from your example
        const rlpHex = '0x01de18171682520894d8da6bf26964af9d7eed9e03e53415d37aa960451580c0';
        
        // When: Decoding the transaction
        final result = service.decodeTransaction(rlpHex);
        
        // Then: Should match expected values
        expect(result, isNotNull);
        expect(result!.transactionType, equals(1));
        expect(result.isLegacy, isFalse);
        expect(result.to?.toLowerCase(), equals('0xd8da6bf26964af9d7eed9e03e53415d37aa96045'));
        expect(result.value, equals(BigInt.from(21)));
        expect(result.gasLimit, equals(BigInt.from(21000)));
        expect(result.gasPrice, equals(BigInt.from(22)));
        expect(result.nonce, equals(BigInt.from(23)));
        expect(result.chainId, equals(BigInt.from(24)));
        expect(result.data, isNull);
        expect(result.accessList, isEmpty);
      });

      test('should decode EIP-2930 transaction (type 1) with access list', () {
        // Given: EIP-2930 transaction with access list from your example
        const rlpHex = '0x01f85a01802082520894d8da6bf26964af9d7eed9e03e53415d37aa960451f83353535f838f794d8da6bf26964af9d7eed9e03e53415d37aa96045e1a00000000000000000000000000000000000000000000000000000000000000001';
        
        // When: Decoding the transaction
        final result = service.decodeTransaction(rlpHex);
        
        // Then: Should match expected values
        expect(result, isNotNull);
        expect(result!.transactionType, equals(1));
        expect(result.isLegacy, isFalse);
        expect(result.to?.toLowerCase(), equals('0xd8da6bf26964af9d7eed9e03e53415d37aa96045'));
        expect(result.value, equals(BigInt.from(31)));
        expect(result.gasLimit, equals(BigInt.from(21000)));
        expect(result.gasPrice, equals(BigInt.from(32)));
        expect(result.nonce, equals(BigInt.from(0)));
        expect(result.chainId, equals(BigInt.from(1)));
        expect(result.data, isNotNull);
        expect(result.accessList, hasLength(1));
        expect(result.accessList![0]['address']?.toLowerCase(), equals('0xd8da6bf26964af9d7eed9e03e53415d37aa96045'));
        expect(result.accessList![0]['storageKeys'], hasLength(1));
        expect(result.accessList![0]['storageKeys'][0], equals('0x0000000000000000000000000000000000000000000000000000000000000001'));
      });

      test('should decode EIP-1559 transaction (type 2) with access list', () {
        // Given: EIP-1559 transaction with access list from your example
        const rlpHex = '0x02f87e2c2b2a2b82520894d8da6bf26964af9d7eed9e03e53415d37aa960452983454545f85bf85994d8da6bf26964af9d7eed9e03e53415d37aa96045f842a00000000000000000000000000000000000000000000000000000000000000001a00000000000000000000000000000000000000000000000000000000000000002';
        
        // When: Decoding the transaction
        final result = service.decodeTransaction(rlpHex);
        
        // Then: Should match expected values
        expect(result, isNotNull);
        expect(result!.transactionType, equals(2));
        expect(result.isLegacy, isFalse);
        expect(result.to?.toLowerCase(), equals('0xd8da6bf26964af9d7eed9e03e53415d37aa96045'));
        expect(result.value, equals(BigInt.from(41)));
        expect(result.gasLimit, equals(BigInt.from(21000)));
        expect(result.maxFeePerGas, equals(BigInt.from(43)));
        expect(result.maxPriorityFeePerGas, equals(BigInt.from(42)));
        expect(result.nonce, equals(BigInt.from(43)));
        expect(result.chainId, equals(BigInt.from(44)));
        expect(result.data, isNotNull);
        expect(result.accessList, hasLength(1));
        expect(result.accessList![0]['address']?.toLowerCase(), equals('0xd8da6bf26964af9d7eed9e03e53415d37aa96045'));
        expect(result.accessList![0]['storageKeys'], hasLength(2));
      });

      test('should decode EIP-1559 transaction (type 2) without access list', () {
        // Given: EIP-1559 transaction without access list from your example
        const rlpHex = '0x02e93736343582520894d8da6bf26964af9d7eed9e03e53415d37aa96045338a0102030405060708090ac0';
        
        // When: Decoding the transaction
        final result = service.decodeTransaction(rlpHex);
        
        // Then: Should match expected values
        expect(result, isNotNull);
        expect(result!.transactionType, equals(2));
        expect(result.isLegacy, isFalse);
        expect(result.to?.toLowerCase(), equals('0xd8da6bf26964af9d7eed9e03e53415d37aa96045'));
        expect(result.value, equals(BigInt.from(51)));
        expect(result.gasLimit, equals(BigInt.from(21000)));
        expect(result.maxFeePerGas, equals(BigInt.from(53)));
        expect(result.maxPriorityFeePerGas, equals(BigInt.from(52)));
        expect(result.nonce, equals(BigInt.from(54)));
        expect(result.chainId, equals(BigInt.from(55)));
        expect(result.data, isNotNull);
        expect(result.accessList, isEmpty);
      });
    });

    group('RLP Encoding Tests', () {
      test('should encode legacy transaction (type 0)', () {
        // Given: Legacy transaction data
        final transaction = EthereumTransactionModel(
          to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
          value: BigInt.from(11),
          gasLimit: BigInt.from(21000),
          gasPrice: BigInt.from(12),
          nonce: BigInt.from(13),
          chainId: BigInt.from(14),
          isLegacy: true,
        );
        
        // When: Encoding the transaction
        final result = service.encodeTransaction(transaction);
        
        // Then: Should match expected RLP encoding
        expect(result?.toLowerCase(), equals('0xdf0d0c82520894d8da6bf26964af9d7eed9e03e53415d37aa960450b800e8080'));
      });

      test('should encode EIP-2930 transaction (type 1) without access list', () {
        // Given: EIP-2930 transaction data
        final transaction = EthereumTransactionModel(
          to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
          value: BigInt.from(21),
          gasLimit: BigInt.from(21000),
          gasPrice: BigInt.from(22),
          nonce: BigInt.from(23),
          chainId: BigInt.from(24),
          isLegacy: false,
          transactionType: 1,
          accessList: [],
        );
        
        // When: Encoding the transaction
        final result = service.encodeTransaction(transaction);
        
        // Then: Should match expected RLP encoding
        expect(result?.toLowerCase(), equals('0x01de18171682520894d8da6bf26964af9d7eed9e03e53415d37aa960451580c0'));
      });

      test('should encode EIP-1559 transaction (type 2) without access list', () {
        // Given: EIP-1559 transaction data
        final transaction = EthereumTransactionModel(
          to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
          value: BigInt.from(51),
          gasLimit: BigInt.from(21000),
          maxFeePerGas: BigInt.from(53),
          maxPriorityFeePerGas: BigInt.from(52),
          nonce: BigInt.from(54),
          chainId: BigInt.from(55),
          isLegacy: false,
          transactionType: 2,
          data: Uint8List.fromList([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a]),
          accessList: [],
        );
        
        // When: Encoding the transaction
        final result = service.encodeTransaction(transaction);
        
        // Then: Should match expected RLP encoding
        expect(result?.toLowerCase(), equals('0x02e93736343582520894d8da6bf26964af9d7eed9e03e53415d37aa96045338a0102030405060708090ac0'));
      });
    });

    group('Transaction Signing Tests', () {
      test('should sign EIP-1559 transaction correctly with private key 0x01', () async {
        // Given: Unsigned EIP-1559 transaction and private key from your example
        const unsignedTx = '0x02e20180010282520894d8da6bf26964af9d7eed9e03e53415d37aa960450183707070c0';
        const privateKey = '0x0000000000000000000000000000000000000000000000000000000000000001';
        
        // First decode the unsigned transaction
        final transaction = service.decodeTransaction(unsignedTx);
        expect(transaction, isNotNull);
        
        // When: Signing the transaction
        final result = await service.signTransaction(transaction!, privateKey);
        
        // Then: Should return the exact signed transaction
        expect(result, equals('0x02f8650180010282520894d8da6bf26964af9d7eed9e03e53415d37aa960450183707070c080a035e2b794bf934bf00db1355cded3ef4a8c27311d9986ac9e5a79fd7b88a87008a022f4ab910bc084f42710a5ccf777725e217697f0009a151397dacb102cddf0d0'));
      });

      test('should derive correct signer address from private key', () {
        // Given: Private key from your example
        const privateKey = '0x0000000000000000000000000000000000000000000000000000000000000001';
        const expectedAddress = '0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf';
        
        // When: Getting address from private key
        final result = service.getAddressFromPrivateKey(privateKey);
        
        // Then: Should match expected address
        expect(result?.toLowerCase(), equals(expectedAddress.toLowerCase()));
      });
    });

    group('Roundtrip Tests', () {
      test('should encode and decode legacy transaction consistently', () {
        // Given: Original transaction
        final original = EthereumTransactionModel(
          to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
          value: BigInt.from(11),
          gasLimit: BigInt.from(21000),
          gasPrice: BigInt.from(12),
          nonce: BigInt.from(13),
          chainId: BigInt.from(14),
          isLegacy: true,
        );
        
        // When: Encoding then decoding
        final encoded = service.encodeTransaction(original);
        expect(encoded, isNotNull);
        final decoded = service.decodeTransaction(encoded!);
        
        // Then: Should match original
        expect(decoded, isNotNull);
        expect(decoded!.to?.toLowerCase(), equals(original.to?.toLowerCase()));
        expect(decoded.value, equals(original.value));
        expect(decoded.gasLimit, equals(original.gasLimit));
        expect(decoded.gasPrice, equals(original.gasPrice));
        expect(decoded.nonce, equals(original.nonce));
        expect(decoded.chainId, equals(original.chainId));
        expect(decoded.isLegacy, equals(original.isLegacy));
      });

      test('should encode and decode EIP-1559 transaction consistently', () {
        // Given: Original EIP-1559 transaction
        final original = EthereumTransactionModel(
          to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
          value: BigInt.from(51),
          gasLimit: BigInt.from(21000),
          maxFeePerGas: BigInt.from(53),
          maxPriorityFeePerGas: BigInt.from(52),
          nonce: BigInt.from(54),
          chainId: BigInt.from(55),
          isLegacy: false,
          transactionType: 2,
          data: Uint8List.fromList([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a]),
          accessList: [],
        );
        
        // When: Encoding then decoding
        final encoded = service.encodeTransaction(original);
        expect(encoded, isNotNull);
        final decoded = service.decodeTransaction(encoded!);
        
        // Then: Should match original
        expect(decoded, isNotNull);
        expect(decoded!.to?.toLowerCase(), equals(original.to?.toLowerCase()));
        expect(decoded.value, equals(original.value));
        expect(decoded.gasLimit, equals(original.gasLimit));
        expect(decoded.maxFeePerGas, equals(original.maxFeePerGas));
        expect(decoded.maxPriorityFeePerGas, equals(original.maxPriorityFeePerGas));
        expect(decoded.nonce, equals(original.nonce));
        expect(decoded.chainId, equals(original.chainId));
        expect(decoded.isLegacy, equals(original.isLegacy));
        expect(decoded.transactionType, equals(original.transactionType));
      });
    });

    group('Additional Verification Tests', () {
      test('should encode EIP-1559 transaction with custom data', () {
        // Given: New test case with different parameters
        final transaction = EthereumTransactionModel(
          chainId: BigInt.from(1),
          nonce: BigInt.from(0),
          maxPriorityFeePerGas: BigInt.from(1),
          maxFeePerGas: BigInt.from(2),
          gasLimit: BigInt.from(21000),
          to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
          value: BigInt.from(1),
          data: Uint8List.fromList([0x70, 0x70, 0x70]),
          accessList: [],
          isLegacy: false,
          transactionType: 2,
        );

        // When: Encoding the transaction
        final result = service.encodeTransaction(transaction);

        // Then: Should match the expected encoding
        expect(result?.toLowerCase(), equals('0x02e20180010282520894d8da6bf26964af9d7eed9e03e53415d37aa960450183707070c0'));
      });

      test('should decode EIP-1559 transaction with custom data', () {
        // Given: Unsigned transaction with custom data
        const unsignedTx = '0x02e20180010282520894d8da6bf26964af9d7eed9e03e53415d37aa960450183707070c0';

        // When: Decoding the transaction
        final result = service.decodeTransaction(unsignedTx);

        // Then: Should correctly parse all fields
        expect(result, isNotNull);
        expect(result!.transactionType, equals(2));
        expect(result.to?.toLowerCase(), equals('0xd8da6bf26964af9d7eed9e03e53415d37aa96045'));
        expect(result.value, equals(BigInt.from(1)));
        expect(result.gasLimit, equals(BigInt.from(21000)));
        expect(result.maxFeePerGas, equals(BigInt.from(2)));
        expect(result.maxPriorityFeePerGas, equals(BigInt.from(1)));
        expect(result.nonce, equals(BigInt.from(0)));
        expect(result.chainId, equals(BigInt.from(1)));
        expect(result.data, isNotNull);
        expect(result.data!.toList(), equals([0x70, 0x70, 0x70]));
        expect(result.accessList, isEmpty);
        expect(result.isLegacy, isFalse);
      });

      test('should derive correct addresses from different private keys', () {
        // Test case 1: Private key 0x02
        const privateKey1 = '0x0000000000000000000000000000000000000000000000000000000000000002';
        const expectedAddress1 = '0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF';
        
        final result1 = service.getAddressFromPrivateKey(privateKey1);
        expect(result1?.toLowerCase(), equals(expectedAddress1.toLowerCase()));

        // Test case 2: Private key 0x03
        const privateKey2 = '0x0000000000000000000000000000000000000000000000000000000000000003';
        const expectedAddress2 = '0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69';
        
        final result2 = service.getAddressFromPrivateKey(privateKey2);
        expect(result2?.toLowerCase(), equals(expectedAddress2.toLowerCase()));
      });

      test('should sign transaction with private key 0x02', () async {
        // Given: Unsigned transaction and private key 0x02
        const unsignedTx = '0x02e20180010282520894d8da6bf26964af9d7eed9e03e53415d37aa960450183707070c0';
        const privateKey = '0x0000000000000000000000000000000000000000000000000000000000000002';
        
        // First decode the unsigned transaction
        final transaction = service.decodeTransaction(unsignedTx);
        expect(transaction, isNotNull);
        
        // When: Signing the transaction
        final result = await service.signTransaction(transaction!, privateKey);
        
        // Then: Should return the exact signed transaction
        expect(result, equals('0x02f8650180010282520894d8da6bf26964af9d7eed9e03e53415d37aa960450183707070c080a0fde4405b5777b75c22e16cb22d8eb592f51dd6bdd07ecb7d1645775e43240cd3a0168d517977fa906ea1ac5566648bc2335af18e2aa935f527266052568edd8dc5'));
      });

      test('should sign transaction with private key 0x03', () async {
        // Given: Unsigned transaction and private key 0x03
        const unsignedTx = '0x02e20180010282520894d8da6bf26964af9d7eed9e03e53415d37aa960450183707070c0';
        const privateKey = '0x0000000000000000000000000000000000000000000000000000000000000003';
        
        // First decode the unsigned transaction
        final transaction = service.decodeTransaction(unsignedTx);
        expect(transaction, isNotNull);
        
        // When: Signing the transaction
        final result = await service.signTransaction(transaction!, privateKey);
        
        // Then: Should return the exact signed transaction
        expect(result, equals('0x02f8650180010282520894d8da6bf26964af9d7eed9e03e53415d37aa960450183707070c001a03325ba8c7d1a6dd2db3af11ff133f67aa65df6fab693a89428b823816bd0c3dfa0794d7b0ceb5a31e27bf35f102cdd654e8107dca504da8ae35a6af6496646a356'));
      });

      test('should handle roundtrip with custom data', () {
        // Given: Original transaction with custom data
        final original = EthereumTransactionModel(
          chainId: BigInt.from(1),
          nonce: BigInt.from(0),
          maxPriorityFeePerGas: BigInt.from(1),
          maxFeePerGas: BigInt.from(2),
          gasLimit: BigInt.from(21000),
          to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
          value: BigInt.from(1),
          data: Uint8List.fromList([0x70, 0x70, 0x70]),
          accessList: [],
          isLegacy: false,
          transactionType: 2,
        );
        
        // When: Encoding then decoding
        final encoded = service.encodeTransaction(original);
        expect(encoded, isNotNull);
        final decoded = service.decodeTransaction(encoded!);
        
        // Then: Should match original (with minor adjustments for parsing)
        expect(decoded, isNotNull);
        expect(decoded!.transactionType, equals(original.transactionType));
        expect(decoded.chainId, equals(original.chainId));
        expect(decoded.nonce, equals(original.nonce));
        expect(decoded.maxPriorityFeePerGas, equals(original.maxPriorityFeePerGas));
        expect(decoded.maxFeePerGas, equals(original.maxFeePerGas));
        expect(decoded.gasLimit, equals(original.gasLimit));
        expect(decoded.value, equals(original.value));
        expect(decoded.data?.toList(), equals(original.data?.toList()));
        expect(decoded.accessList, isEmpty);
        expect(decoded.isLegacy, equals(original.isLegacy));
      });

      test('should handle various data payloads', () {
        // Test with different data sizes and values
        final testCases = [
          {'data': [0x01], 'description': 'single byte'},
          {'data': [0x70, 0x70, 0x70], 'description': 'three bytes'},
          {'data': [0xff, 0x00, 0x55, 0xaa], 'description': 'mixed bytes'},
          {'data': <int>[], 'description': 'empty data'},
        ];

        for (final testCase in testCases) {
          final data = testCase['data'] as List<int>;
          final description = testCase['description'] as String;
          
          final transaction = EthereumTransactionModel(
            chainId: BigInt.from(1),
            nonce: BigInt.from(0),
            maxPriorityFeePerGas: BigInt.from(1),
            maxFeePerGas: BigInt.from(2),
            gasLimit: BigInt.from(21000),
            to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
            value: BigInt.from(1),
            data: data.isNotEmpty ? Uint8List.fromList(data) : null,
            accessList: [],
            isLegacy: false,
            transactionType: 2,
          );
          
          // Test roundtrip encoding/decoding
          final encoded = service.encodeTransaction(transaction);
          expect(encoded, isNotNull, reason: 'Failed to encode transaction with $description');
          
          final decoded = service.decodeTransaction(encoded!);
          expect(decoded, isNotNull, reason: 'Failed to decode transaction with $description');
          expect(decoded!.data?.toList() ?? [], equals(data), reason: 'Data mismatch for $description');
        }
      });
    });

    // New test 1: Encoding with long data (copy of existing encoding test)
    test('should encode EIP-1559 transaction with long data', () {
      final transaction = EthereumTransactionModel(
        to: '0xD8dA6bf26964AF9D7EeD9E03E53415D37aa96000',
        value: BigInt.one,
        gasLimit: BigInt.from(21000),
        maxFeePerGas: BigInt.two,
        maxPriorityFeePerGas: BigInt.one,
        nonce: BigInt.zero,
        chainId: BigInt.one,
        isLegacy: false,
        transactionType: 2,
        data: Uint8List.fromList(hex.decode('707070444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444')),
        accessList: [],
      );
      
      final result = service.encodeTransaction(transaction);
      expect(result?.toLowerCase(), equals('0x02f8550180010282520894d8da6bf26964af9d7eed9e03e53415d37aa9600001b6707070444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444c0'));
    });

    // New test 2: Decoding with long data (copy of existing decoding test)
    test('should decode EIP-1559 transaction with long data', () {
      const rlpHex = '0x02f8550180010282520894d8da6bf26964af9d7eed9e03e53415d37aa9600001b6707070444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444c0';
      
      final result = service.decodeTransaction(rlpHex);
      
      expect(result, isNotNull);
      expect(result!.transactionType, equals(2));
      expect(result.to?.toLowerCase(), equals('0xd8da6bf26964af9d7eed9e03e53415d37aa96000'));
      expect(result.value, equals(BigInt.one));
      expect(result.gasLimit, equals(BigInt.from(21000)));
      expect(result.maxFeePerGas, equals(BigInt.two));
      expect(result.maxPriorityFeePerGas, equals(BigInt.one));
      expect(result.nonce, equals(BigInt.zero));
      expect(result.chainId, equals(BigInt.one));
      expect(result.data, isNotNull);
      expect(result.accessList, isEmpty);
    });

    // New test 3: Signing with private key 0x04 (copy of existing signing test)
    test('should sign EIP-1559 transaction with private key 0x04', () async {
      const unsignedTx = '0x02e20180010282520894d8da6bf26964af9d7eed9e03e53415d37aa960450183707070c0';
      const privateKey = '0x0000000000000000000000000000000000000000000000000000000000000004';
      
      final transaction = service.decodeTransaction(unsignedTx);
      expect(transaction, isNotNull);
      
      final result = await service.signTransaction(transaction!, privateKey);
      
      // Then: Should return the exact signed transaction
      expect(result, equals('0x02f8650180010282520894d8da6bf26964af9d7eed9e03e53415d37aa960450183707070c001a01551a9f164ce0754a17eb72d3ad344e5a5c3b1140caa2156fc802affae5b797ba008286de3c2e3dbd828300549ff33f785df858800084fcd408bdf554235536d2b'));
    });
  });
}
