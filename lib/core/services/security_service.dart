import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

class SecurityService {
  final _storage = const FlutterSecureStorage();
  static const _pinKey = 'app_pin';
  static const _requirePinKey = 'require_pin_on_launch';

  /// Hash the PIN for cloud storage using SHA-256
  String hashPin(String pin) {
    var bytes = utf8.encode(pin); 
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Store the raw PIN locally in secure storage
  Future<void> saveLocalPin(String pin, bool requireOnLaunch) async {
    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _requirePinKey, value: requireOnLaunch.toString());
  }

  /// Check if the local secure storage has a PIN and if it is required on launch
  Future<bool> isAppLockEnabledOnLaunch() async {
    final requireStr = await _storage.read(key: _requirePinKey);
    return requireStr == 'true';
  }

  /// Update the require on launch preference locally
  Future<void> setAppLockEnabledOnLaunch(bool requireOnLaunch) async {
    await _storage.write(key: _requirePinKey, value: requireOnLaunch.toString());
  }

  /// Verify local PIN
  Future<bool> verifyLocalPin(String pin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin == pin;
  }
  
  Future<String?> getLocalPin() async {
    return await _storage.read(key: _pinKey);
  }

  /// Verify against a hash (useful for Force Logout)
  bool verifyPinHash(String pin, String hash) {
    return hashPin(pin) == hash;
  }
}
