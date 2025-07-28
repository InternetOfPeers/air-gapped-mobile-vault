# Air Gapped Mobile Vault - Copilot Instructions

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

## Project Overview

This is a production-ready Flutter mobile application designed as an air gapped secret vault for signing Ethereum transactions offline. The app operates completely offline with enterprise-grade security and supports all modern Ethereum transaction types.

## Current Implementation Status

### ✅ **Core Features Complete**

- **Cryptographic Security**: Real ECDSA signing using web3dart library (not hardcoded signatures)
- **RLP Encoding/Decoding**: Custom implementation supporting Legacy, EIP-2930, and EIP-1559 transactions
- **Access List Support**: Full encoding/decoding for EIP-2930 and EIP-1559 transactions
- **Secure Storage**: Device keystore integration via flutter_secure_storage
- **QR Code Support**: Full scanning and generation pipeline with validation
- **Precise Value Formatting**: BigInt-based decimal formatting for wei/ETH/Gwei conversions
- **Comprehensive Testing**: 48 tests covering all transaction types and edge cases

### 🏗️ **Architecture**

```
lib/
├── models/
│   └── ethereum_transaction.dart     # Transaction model with all EIP support
├── services/
│   ├── ethereum_transaction_service.dart  # Core RLP + signing service
│   ├── key_storage_service.dart          # Secure storage management
│   └── qr_code_service.dart              # QR scanning/validation
├── screens/
│   ├── home_screen.dart                  # Main dashboard
│   ├── key_management_screen.dart        # Private key management
│   ├── transaction_signing_screen.dart   # Transaction review + signing
│   ├── qr_private_key_scanner_screen.dart
│   ├── qr_transaction_scanner_screen.dart
│   └── settings_screen.dart
├── widgets/
│   └── secure_card.dart                 # Security-focused UI component
└── theme/
    └── app_theme.dart                   # Consistent styling
```

## Key Technical Requirements

### **Security First**

- Use device keystore/keychain for all private key storage
- No network access - completely offline operation
- No tracking, logging, analytics, or user data collection
- Private key validation using secp256k1 curve parameters
- Secure QR code validation before processing

### **Ethereum Compatibility**

- **Legacy Transactions**: Full RLP encoding/decoding with proper signature handling
- **EIP-2930**: Access list transaction support with gas optimization
- **EIP-1559**: Dynamic fee transactions with maxFeePerGas and maxPriorityFeePerGas
- **Real Cryptography**: Authentic ECDSA signatures via web3dart's signToEcSignature
- **Precise Formatting**: BigInt decimal math for accurate wei/ETH/Gwei display

### **Cross-Platform Support**

- Android 9+ with encrypted shared preferences
- iOS with keychain integration
- Consistent UI/UX across platforms

## Current Dependencies (pubspec.yaml)

### **Core Framework**

- `flutter`: SDK framework
- `cupertino_icons: ^1.0.8`: iOS-style icons

### **Security & Storage**

- `flutter_secure_storage: ^9.2.2`: Device keystore integration
- `permission_handler: ^11.3.1`: Camera permissions for QR scanning

### **QR Code Functionality**

- `mobile_scanner: ^7.0.1`: Camera-based QR code scanning
- `qr_flutter: ^4.1.0`: QR code generation

### **Ethereum & Cryptography**

- `web3dart: ^3.0.1`: Ethereum wallet functionality and ECDSA signing
- `pointycastle: ^4.0.0`: Cryptographic primitives
- `crypto: ^3.0.5`: Hash functions and utilities
- `convert: ^3.1.1`: Hex encoding/decoding
- `rlp: ^2.0.0`: RLP encoding library (note: custom implementation used)

## Development Guidelines

### **Code Quality Standards**

- Singleton pattern for services (`Service.instance`)
- Comprehensive error handling with null safety
- Extensive test coverage (currently 48 tests passing)
- Clean separation of concerns (models, services, screens)
- BigInt arithmetic for all cryptocurrency value calculations

### **Security Practices**

- Never log or expose private keys in any form
- Validate all user input before processing
- Use const constructors and immutable data structures
- Implement proper disposal of sensitive data
- Follow principle of least privilege for permissions

### **UI/UX Patterns**

- Material Design 3 theming with consistent styling
- Conditional widget rendering using spread operators: `if (condition) ...[widget, SizedBox(height: 12)]`
- SecureCard widget for displaying sensitive information
- Loading states and error handling throughout
- Accessibility-first design principles

### **Testing Requirements**

- Unit tests for all services and models
- Integration tests for transaction flows
- Format testing for decimal precision
- Edge case coverage for boundary conditions
- Mock data for offline testing scenarios

### **Maintenance Notes**

- Custom RLP implementation preferred over external library for security audit
- Formatting functions use `_formatBigIntWithDecimals()` helper for consistency
- All transaction validation occurs in QRCodeService before processing
- Secure storage initialization required before any key operations

## Current State Summary

The project is feature-complete with production-ready security, comprehensive Ethereum transaction support, and a robust test suite. All major components are implemented and tested. Focus should be on maintaining security standards, expanding test coverage, and ensuring UI consistency across platforms.
