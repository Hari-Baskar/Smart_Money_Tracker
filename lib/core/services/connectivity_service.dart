import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum NetworkStatus {
  connected,
  disconnected,
  checking,
}

class NetworkStatusNotifier extends Notifier<NetworkStatus> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _subscription;

  @override
  NetworkStatus build() {
    // Schedule asynchronous initialization
    _init();

    // Register cleanup when provider is disposed
    ref.onDispose(() {
      _subscription?.cancel();
    });

    return NetworkStatus.checking;
  }

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateStatus(results);
    } catch (e) {
      debugPrint('Error checking initial connectivity: $e');
      state = NetworkStatus.disconnected;
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  Future<void> _updateStatus(List<ConnectivityResult> results) async {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      state = NetworkStatus.disconnected;
      return;
    }

    state = NetworkStatus.checking;
    final hasInternet = await checkRealInternetAccess();
    if (hasInternet) {
      state = NetworkStatus.connected;
    } else {
      state = NetworkStatus.disconnected;
    }
  }

  Future<bool> checkRealInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {
      // Lookup failed, timed out, or no internet backhaul
    }
    return false;
  }

  Future<bool> checkConnection() async {
    state = NetworkStatus.checking;
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        state = NetworkStatus.disconnected;
        return false;
      }
      final hasInternet = await checkRealInternetAccess();
      if (hasInternet) {
        state = NetworkStatus.connected;
        return true;
      } else {
        state = NetworkStatus.disconnected;
        return false;
      }
    } catch (_) {
      state = NetworkStatus.disconnected;
      return false;
    }
  }
}

final networkStatusProvider =
    NotifierProvider<NetworkStatusNotifier, NetworkStatus>(() {
  return NetworkStatusNotifier();
});
