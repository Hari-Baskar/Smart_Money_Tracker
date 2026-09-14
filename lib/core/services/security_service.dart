import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

class SecurityService {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  static const _requireAppLockKey = 'require_app_lock_on_launch';
  bool? _cachedValue;

  /// Check if App Lock is enabled (instant from memory/SharedPreferences cache)
  Future<bool> isAppLockEnabledOnLaunch() async {
    if (_cachedValue != null) return _cachedValue!;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_requireAppLockKey)) {
        _cachedValue = prefs.getBool(_requireAppLockKey) ?? false;
        return _cachedValue!;
      }
    } catch (_) {}

    try {
      final requireStr = await _storage.read(key: _requireAppLockKey);
      _cachedValue = requireStr == 'true';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_requireAppLockKey, _cachedValue!);
      return _cachedValue!;
    } catch (_) {
      return false;
    }
  }

  /// Update the require on launch preference locally
  Future<void> setAppLockEnabledOnLaunch(bool requireOnLaunch) async {
    _cachedValue = requireOnLaunch;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_requireAppLockKey, requireOnLaunch);
    } catch (_) {}

    try {
      await _storage.write(
        key: _requireAppLockKey,
        value: requireOnLaunch.toString(),
      );
    } catch (_) {}
  }

  /// Authenticate using device biometrics or device passcode/pattern
  Future<bool> authenticateWithBiometrics(String reason) async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();

      if (!isAvailable) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
        biometricOnly: false, // fallback to device passcode if biometrics fail
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Clear all secure storage data
  Future<void> clearAll() async {
    _cachedValue = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_requireAppLockKey);
    } catch (_) {}
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
