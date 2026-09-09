import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service that provides trusted real-world network time (HTTPS Date / NTP)
/// immune to device system clock manipulations.
class TimeService {
  static final TimeService _instance = TimeService._internal();
  factory TimeService() => _instance;
  TimeService._internal();

  static const String _prefOffsetKey = 'network_time_offset_ms';
  static const String _prefLastSyncKey = 'network_time_last_sync_ms';

  static const List<String> _httpServers = [
    'https://www.google.com',
    'https://cloudflare.com',
    'https://www.apple.com',
  ];

  static const List<String> _ntpHosts = [
    'time.google.com',
    'time.cloudflare.com',
    'pool.ntp.org',
  ];

  DateTime? _syncedTime;
  final Stopwatch _stopwatch = Stopwatch();
  Duration _offset = Duration.zero;
  bool _isSynced = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Returns trusted network time if synchronized, or cached offset adjusted time.
  static DateTime now() {
    return _instance._getCurrentTime();
  }

  /// Returns true if at least one network sync succeeded.
  static bool get isSynced => _instance._isSynced;

  /// Returns the current offset duration between network time and system clock.
  static Duration get offset => _instance._offset;

  DateTime _getCurrentTime() {
    if (_isSynced && _syncedTime != null && _stopwatch.isRunning) {
      // Monotonic time elapsed since last verified network sync (immune to device clock tampering)
      return _syncedTime!.add(_stopwatch.elapsed);
    }
    // Fallback using stored offset applied to device clock
    return DateTime.now().add(_offset);
  }

  /// Initializes the service, restores cached offset, and initiates background sync.
  static Future<void> initialize() async {
    await _instance._init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedOffsetMs = prefs.getInt(_prefOffsetKey);
      if (storedOffsetMs != null) {
        _offset = Duration(milliseconds: storedOffsetMs);
      }

      // Initial background sync
      unawaited(syncTime());

      // Re-sync whenever network connectivity is restored
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
        final hasConnection = results.any((r) => r != ConnectivityResult.none);
        if (hasConnection) {
          syncTime();
        }
      });
    } catch (e) {
      debugPrint('TimeService init error: $e');
    }
  }

  /// Synchronizes time with HTTP servers (primary) or NTP (fallback).
  Future<bool> syncTime() async {
    // 1. Primary: HTTPS Date header (carrier-friendly, IPv4/IPv6 dual-stack compliant)
    for (final url in _httpServers) {
      try {
        final httpTime = await _getHttpTime(url).timeout(const Duration(seconds: 4));
        if (httpTime != null) {
          _applySyncedTime(httpTime);
          return true;
        }
      } catch (_) {}
    }

    // 2. Secondary: NTP with address family matching
    for (final host in _ntpHosts) {
      try {
        final ntpTime = await _getNtpTime(host).timeout(const Duration(seconds: 3));
        if (ntpTime != null) {
          _applySyncedTime(ntpTime);
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  void _applySyncedTime(DateTime networkTime) async {
    final systemNow = DateTime.now();
    _offset = networkTime.difference(systemNow);
    _syncedTime = networkTime;
    _stopwatch.reset();
    _stopwatch.start();
    _isSynced = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefOffsetKey, _offset.inMilliseconds);
      await prefs.setInt(_prefLastSyncKey, networkTime.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('TimeService persist error: $e');
    }
  }

  Future<DateTime?> _getHttpTime(String url) async {
    HttpClient? client;
    try {
      final start = DateTime.now().millisecondsSinceEpoch;
      client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      final request = await client.headUrl(Uri.parse(url));
      final response = await request.close();
      final end = DateTime.now().millisecondsSinceEpoch;
      final roundTrip = end - start;

      final dateHeader = response.headers.value(HttpHeaders.dateHeader);
      if (dateHeader != null) {
        final serverTime = HttpDate.parse(dateHeader).toLocal();
        // Adjust for half of round-trip network transit latency
        return serverTime.add(Duration(milliseconds: roundTrip ~/ 2));
      }
    } catch (_) {
      return null;
    } finally {
      client?.close();
    }
    return null;
  }

  Future<DateTime?> _getNtpTime(String host) async {
    RawDatagramSocket? client;
    try {
      final addresses = await InternetAddress.lookup(host);
      if (addresses.isEmpty) return null;

      final targetAddress = addresses.first;
      // Match socket bind family with target address family (IPv4 vs IPv6)
      final bindAddress = targetAddress.type == InternetAddressType.IPv6
          ? InternetAddress.anyIPv6
          : InternetAddress.anyIPv4;

      client = await RawDatagramSocket.bind(bindAddress, 0);
      final buffer = Uint8List(48);
      // NTP client request header: LI=0, VN=3, Mode=3 (Client) -> 0x1B
      buffer[0] = 0x1B;

      final completer = Completer<DateTime?>();
      final startTime = DateTime.now().millisecondsSinceEpoch;

      client.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            try {
              final datagram = client?.receive();
              if (datagram != null && datagram.data.length >= 48) {
                final endTime = DateTime.now().millisecondsSinceEpoch;
                final roundTrip = endTime - startTime;

                final byteData = ByteData.view(
                  datagram.data.buffer,
                  datagram.data.offsetInBytes,
                  datagram.data.lengthInBytes,
                );

                // Transmit Timestamp (seconds and fraction since 1900)
                final secondsSince1900 = byteData.getUint32(40, Endian.big);
                final fraction = byteData.getUint32(44, Endian.big);

                if (secondsSince1900 > 0) {
                  // 1900 to 1970 offset in seconds: 2208988800
                  final secondsSince1970 = secondsSince1900 - 2208988800;
                  final fractionMs = (fraction * 1000) ~/ 4294967296;
                  final milliseconds = (secondsSince1970 * 1000) + fractionMs;

                  final adjustedMs = milliseconds + (roundTrip ~/ 2);
                  if (!completer.isCompleted) {
                    completer.complete(
                      DateTime.fromMillisecondsSinceEpoch(adjustedMs, isUtc: true).toLocal(),
                    );
                  }
                }
              }
            } catch (_) {
              if (!completer.isCompleted) completer.complete(null);
            }
          }
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(null);
        },
        cancelOnError: true,
      );

      client.send(buffer, targetAddress, 123);
      return await completer.future.timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    } finally {
      client?.close();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
