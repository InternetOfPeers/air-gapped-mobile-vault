# Air Gapped Mobile Vault

A secure, offline mobile application for storing Ethereum private keys and signing transactions. This app is designed to work completely offline with no network access, ensuring maximum security for your private keys.

You can use the [Ethereum Transaction Tools](https://github.com/InternetOfPeers/ethereum-transaction-tools) repo to generate and read transactions in QR code format.

## Features

- 🔐 **Secure Key Storage**: Uses device keystore/keychain for maximum security
- 📱 **Cross-Platform**: Supports Android 9+ and iOS
- 🔒 **Completely Offline**: No network access required or allowed
- 🚫 **No Tracking**: Zero analytics, logging, or data collection
- 📷 **QR Code Support**: Scan QR codes for private keys and transactions
- ✅ **Transaction Signing**: Sign Ethereum transactions with RLP encoding
- 📱 **Modern UI**: Clean and intuitive mobile interface

## Security Features

- Hardware-backed key storage (when available)
- Encrypted secure storage using platform APIs
- No debug logging or crash reporting
- Memory cleared after sensitive operations
- Input validation and sanitization
- Secure random number generation

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / Xcode for mobile development
- A physical device (recommended for security testing)

### Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd air-gapped-mobile-vault
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

## Usage

### Importing Private Keys

1. **Manual Entry**: Navigate to Key Management → Import Private Key
2. **QR Code**: Use the QR scanner to import keys from QR codes

### Signing Transactions

1. Scan a QR code containing an unsigned RLP-encoded Ethereum transaction
2. Review the transaction details carefully
3. Select the private key to use for signing
4. Confirm and sign the transaction
5. Generate a QR code with the signed transaction for broadcasting

### Security Best Practices

- Always verify transaction details before signing
- Keep your device secure with PIN/biometric authentication
- Never share your private keys or QR codes
- Use this app on a dedicated offline device when possible
- Regularly backup your private keys securely

## Architecture

The app follows clean architecture principles with:

- **Services**: Core business logic and external integrations
- **Models**: Data structures for Ethereum transactions
- **Screens**: UI components and user interaction
- **Widgets**: Reusable UI components
- **Theme**: Consistent styling throughout the app

## Dependencies

Key libraries used:

- `flutter_secure_storage`: Secure key storage
- `web3dart`: Ethereum transaction handling
- `qr_code_scanner`: QR code scanning
- `qr_flutter`: QR code generation
- `pointycastle`: Cryptographic operations
- `permission_handler`: Camera permissions

## Supported Networks

The app supports all Ethereum networks including:

- Ethereum Mainnet
- Testnets (Goerli, Sepolia)
- Layer 2 networks (Polygon, BSC)
- Custom networks (via chain ID)

## Privacy Policy

This app:

- ❌ Does NOT collect any personal data
- ❌ Does NOT use analytics or tracking
- ❌ Does NOT connect to the internet
- ❌ Does NOT store data in the cloud
- ✅ Stores all data locally in encrypted format
- ✅ Uses hardware security features when available

## Security Considerations

⚠️ **Important Security Notes:**

- This app is designed for offline use on secure devices
- Private keys are stored in the device's secure enclave/keystore
- Always verify you're running an authentic version of the app
- Consider using on a dedicated offline device for maximum security
- Keep your device updated with latest security patches

## Development

### Building for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Running Tests

```bash
flutter test
```

## Contributing

This project prioritizes security and privacy. When contributing:

1. Follow security best practices
2. No network-related dependencies
3. Maintain offline-only functionality
4. Add tests for security-critical code
5. Document security implications

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This software is provided "as is" without warranty. Users are responsible for:

- Securing their devices and private keys
- Verifying transaction details before signing
- Maintaining backups of their private keys
- Understanding the risks of cryptocurrency transactions

Always test with small amounts first and never invest more than you can afford to lose.
