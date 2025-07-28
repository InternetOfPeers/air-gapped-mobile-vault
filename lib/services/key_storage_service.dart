import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service for securely storing and managing Ethereum private keys
/// Uses the device's secure keystore/keychain for maximum security
class KeyStorageService {
  static final KeyStorageService _instance = KeyStorageService._internal();
  static KeyStorageService get instance => _instance;
  
  KeyStorageService._internal();

  late FlutterSecureStorage _secureStorage;
  
  static const String _keyPrefix = 'eth_key_';
  static const String _keyListKey = 'stored_keys_list';

  /// Initialize the secure storage with the most secure options available
  Future<void> initialize() async {
    // Configure secure storage with the highest security settings
    const androidOptions = AndroidOptions(
      encryptedSharedPreferences: true,
    );
    
    const iosOptions = IOSOptions(
      synchronizable: false,
    );

    _secureStorage = const FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iosOptions,
    );
  }

  /// Store a private key securely with a given alias
  Future<bool> storePrivateKey(String alias, String privateKeyHex) async {
    try {
      // Validate the private key format
      if (!_isValidPrivateKey(privateKeyHex)) {
        throw ArgumentError('Invalid private key format');
      }

      // Generate a unique storage key
      final storageKey = _keyPrefix + alias;
      
      // Store the key
      await _secureStorage.write(key: storageKey, value: privateKeyHex);
      
      // Update the list of stored keys
      await _updateKeysList(alias, add: true);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Retrieve a private key by alias
  Future<String?> getPrivateKey(String alias) async {
    try {
      final storageKey = _keyPrefix + alias;
      return await _secureStorage.read(key: storageKey);
    } catch (e) {
      return null;
    }
  }

  /// Get list of all stored key aliases
  Future<List<String>> getStoredKeyAliases() async {
    try {
      final keysList = await _secureStorage.read(key: _keyListKey);
      if (keysList == null) return [];
      
      final List<dynamic> aliases = jsonDecode(keysList);
      return aliases.cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// Delete a stored private key
  Future<bool> deletePrivateKey(String alias) async {
    try {
      final storageKey = _keyPrefix + alias;
      await _secureStorage.delete(key: storageKey);
      
      // Update the list of stored keys
      await _updateKeysList(alias, add: false);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if a key with the given alias exists
  Future<bool> hasKey(String alias) async {
    try {
      final key = await getPrivateKey(alias);
      return key != null;
    } catch (e) {
      return false;
    }
  }

  /// Clear all stored keys (use with caution!)
  Future<bool> clearAllKeys() async {
    try {
      await _secureStorage.deleteAll();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate private key format (hex string, 64 characters)
  bool _isValidPrivateKey(String privateKeyHex) {
    // Remove 0x prefix if present
    final cleanHex = privateKeyHex.startsWith('0x') 
        ? privateKeyHex.substring(2) 
        : privateKeyHex;
    
    // Check if it's a valid hex string of correct length
    if (cleanHex.length != 64) return false;
    
    try {
      int.parse(cleanHex, radix: 16);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update the internal list of stored key aliases
  Future<void> _updateKeysList(String alias, {required bool add}) async {
    try {
      final currentAliases = await getStoredKeyAliases();
      
      if (add) {
        if (!currentAliases.contains(alias)) {
          currentAliases.add(alias);
        }
      } else {
        currentAliases.remove(alias);
      }
      
      await _secureStorage.write(
        key: _keyListKey, 
        value: jsonEncode(currentAliases),
      );
    } catch (e) {
      // Handle error silently - the key is stored, list update failed
    }
  }

  /// Generate a hash of the private key for display purposes (never store this!)
  String getKeyFingerprint(String privateKeyHex) {
    final bytes = utf8.encode(privateKeyHex);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8).toUpperCase();
  }
}
