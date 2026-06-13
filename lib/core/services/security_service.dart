import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

class SecurityService {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  static const _requireAppLockKey = 'require_app_lock_on_launch';

  /// Check if the local secure storage has App Lock required on launch
  Future<bool> isAppLockEnabledOnLaunch() async {
    final requireStr = await _storage.read(key: _requireAppLockKey);
    return requireStr == 'true';
  }

  /// Update the require on launch preference locally
  Future<void> setAppLockEnabledOnLaunch(bool requireOnLaunch) async {
    await _storage.write(key: _requireAppLockKey, value: requireOnLaunch.toString());
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
    await _storage.deleteAll();
  }
}
