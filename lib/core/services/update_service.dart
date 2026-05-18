import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/app_config_model.dart';

enum UpdateStatus {
  none,
  optional,
  mandatory,
}

class UpdateState {
  final UpdateStatus status;
  final AppConfig? config;
  final String currentVersion;

  UpdateState({
    required this.status,
    this.config,
    required this.currentVersion,
  });

  UpdateState copyWith({
    UpdateStatus? status,
    AppConfig? config,
    String? currentVersion,
  }) {
    return UpdateState(
      status: status ?? this.status,
      config: config ?? this.config,
      currentVersion: currentVersion ?? this.currentVersion,
    );
  }
}

class UpdateNotifier extends AsyncNotifier<UpdateState> {
  @override
  Future<UpdateState> build() async {
    return _checkUpdate();
  }

  Future<UpdateState> _checkUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('app_config')
        .get();

    if (!doc.exists) {
      return UpdateState(
        status: UpdateStatus.none,
        currentVersion: currentVersion,
      );
    }

    final config = AppConfig.fromMap(doc.data()!);
    final status = _calculateUpdateStatus(currentVersion, config);

    return UpdateState(
      status: status,
      config: config,
      currentVersion: currentVersion,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _checkUpdate());
  }

  UpdateStatus _calculateUpdateStatus(String current, AppConfig config) {
    if (_isVersionLessThan(current, config.minVersion)) {
      return UpdateStatus.mandatory;
    } else if (_isVersionLessThan(current, config.maxVersion)) {
      return UpdateStatus.optional;
    }
    return UpdateStatus.none;
  }

  bool _isVersionLessThan(String v1, String v2) {
    List<int> v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    int maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    for (int i = 0; i < maxLength; i++) {
      int v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      int v2Part = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1Part < v2Part) return true;
      if (v1Part > v2Part) return false;
    }
    return false;
  }
}

final updateProvider = AsyncNotifierProvider<UpdateNotifier, UpdateState>(() {
  return UpdateNotifier();
});
