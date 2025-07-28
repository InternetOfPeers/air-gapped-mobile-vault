import 'package:flutter_test/flutter_test.dart';
import 'package:air_gapped_vault/services/ethereum_transaction_service.dart';

void main() {
  group('EthereumTransactionService Formatting Tests', () {
    late EthereumTransactionService service;

    setUp(() {
      service = EthereumTransactionService.instance;
    });

    group('formatWeiToEther', () {
      test('should format zero wei correctly', () {
        expect(service.formatWeiToEther(BigInt.zero), equals('0 ETH'));
      });

      test('should format 1 wei correctly', () {
        expect(service.formatWeiToEther(BigInt.one), equals('0.000000000000000001 ETH'));
      });

      test('should format small wei amounts correctly', () {
        expect(service.formatWeiToEther(BigInt.from(100)), equals('0.0000000000000001 ETH'));
        expect(service.formatWeiToEther(BigInt.from(1000)), equals('0.000000000000001 ETH'));
      });

      test('should format 1 gwei in wei correctly', () {
        final oneGwei = BigInt.from(1000000000); // 1e9 wei = 1 gwei
        expect(service.formatWeiToEther(oneGwei), equals('0.000000001 ETH'));
      });

      test('should format 1 finney (0.001 ETH) correctly', () {
        final oneFinney = BigInt.from(1000000000000000); // 1e15 wei = 0.001 ETH
        expect(service.formatWeiToEther(oneFinney), equals('0.001 ETH'));
      });

      test('should format 1 ether correctly', () {
        final oneEther = BigInt.parse('1000000000000000000'); // 1e18 wei = 1 ETH
        expect(service.formatWeiToEther(oneEther), equals('1 ETH'));
      });

      test('should format 1.5 ether correctly', () {
        final oneAndHalfEther = BigInt.parse('1500000000000000000'); // 1.5e18 wei
        expect(service.formatWeiToEther(oneAndHalfEther), equals('1.5 ETH'));
      });

      test('should format large amounts correctly', () {
        final largeAmount = BigInt.parse('12345678900000000000000'); // 12345.6789 ETH
        expect(service.formatWeiToEther(largeAmount), equals('12345.6789 ETH'));
      });

      test('should handle precise decimals correctly', () {
        final preciseAmount = BigInt.parse('1234567890123456789'); // 1.234567890123456789 ETH
        expect(service.formatWeiToEther(preciseAmount), equals('1.234567890123456789 ETH'));
      });
    });

    group('formatGasPrice', () {
      test('should format zero gas price correctly', () {
        expect(service.formatGasPrice(BigInt.zero), equals('0 Gwei'));
      });

      test('should format 1 wei gas price correctly', () {
        expect(service.formatGasPrice(BigInt.one), equals('0.000000001 Gwei'));
      });

      test('should format 2 wei gas price correctly', () {
        expect(service.formatGasPrice(BigInt.two), equals('0.000000002 Gwei'));
      });

      test('should format small wei amounts correctly', () {
        expect(service.formatGasPrice(BigInt.from(100)), equals('0.0000001 Gwei'));
        expect(service.formatGasPrice(BigInt.from(1000)), equals('0.000001 Gwei'));
        expect(service.formatGasPrice(BigInt.from(10000)), equals('0.00001 Gwei'));
      });

      test('should format 1 gwei correctly', () {
        final oneGwei = BigInt.from(1000000000); // 1e9 wei = 1 gwei
        expect(service.formatGasPrice(oneGwei), equals('1 Gwei'));
      });

      test('should format fractional gwei correctly', () {
        final halfGwei = BigInt.from(500000000); // 0.5e9 wei = 0.5 gwei
        expect(service.formatGasPrice(halfGwei), equals('0.5 Gwei'));
      });

      test('should format typical gas prices correctly', () {
        final twentyGwei = BigInt.from(20000000000); // 20e9 wei = 20 gwei
        expect(service.formatGasPrice(twentyGwei), equals('20 Gwei'));
      });

      test('should format high gas prices correctly', () {
        final highGasPrice = BigInt.from(100000000000); // 100e9 wei = 100 gwei
        expect(service.formatGasPrice(highGasPrice), equals('100 Gwei'));
      });

      test('should format precise gas prices correctly', () {
        final preciseGasPrice = BigInt.from(12345678900); // 12.3456789 gwei
        expect(service.formatGasPrice(preciseGasPrice), equals('12.3456789 Gwei'));
      });

      test('should format very small gas prices correctly', () {
        final verySmallGasPrice = BigInt.from(1000000); // 0.001 gwei
        expect(service.formatGasPrice(verySmallGasPrice), equals('0.001 Gwei'));
      });

      test('should format extremely small gas prices correctly', () {
        final extremelySmallGasPrice = BigInt.from(1000); // 0.000001 gwei
        expect(service.formatGasPrice(extremelySmallGasPrice), equals('0.000001 Gwei'));
      });
    });

    group('Real Transaction Values', () {
      test('should format the provided transaction values correctly', () {
        // Values from the user's transaction:
        // Value: 1 wei
        // Max Fee Per Gas: 2 wei  
        // Max Priority Fee Per Gas: 1 wei
        
        expect(service.formatWeiToEther(BigInt.one), equals('0.000000000000000001 ETH'));
        expect(service.formatGasPrice(BigInt.two), equals('0.000000002 Gwei'));
        expect(service.formatGasPrice(BigInt.one), equals('0.000000001 Gwei'));
      });

      test('should format typical mainnet transaction values', () {
        // Typical mainnet values
        final typicalValue = BigInt.parse('100000000000000000'); // 0.1 ETH
        final typicalGasPrice = BigInt.from(20000000000); // 20 gwei
        final typicalPriorityFee = BigInt.from(2000000000); // 2 gwei
        
        expect(service.formatWeiToEther(typicalValue), equals('0.1 ETH'));
        expect(service.formatGasPrice(typicalGasPrice), equals('20 Gwei'));
        expect(service.formatGasPrice(typicalPriorityFee), equals('2 Gwei'));
      });

      test('should format high-value transactions correctly', () {
        final highValue = BigInt.parse('10000000000000000000'); // 10 ETH
        final highGasPrice = BigInt.from(100000000000); // 100 gwei
        
        expect(service.formatWeiToEther(highValue), equals('10 ETH'));
        expect(service.formatGasPrice(highGasPrice), equals('100 Gwei'));
      });
    });

    group('Edge Cases', () {
      test('should handle maximum safe integer values', () {
        // Test with large but reasonable values
        final largeValue = BigInt.parse('1000000000000000000000000'); // 1,000,000 ETH
        expect(service.formatWeiToEther(largeValue), contains('1000000'));
      });

      test('should remove trailing zeros appropriately', () {
        final exactHalf = BigInt.parse('500000000000000000'); // 0.5 ETH exactly
        expect(service.formatWeiToEther(exactHalf), equals('0.5 ETH'));
        
        final exactTen = BigInt.from(10000000000); // 10 gwei exactly
        expect(service.formatGasPrice(exactTen), equals('10 Gwei'));
      });
    });
  });
}
