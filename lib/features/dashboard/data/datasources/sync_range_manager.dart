import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SyncDateRange {
  final DateTime start;
  final DateTime end;

  SyncDateRange(this.start, this.end);

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };

  factory SyncDateRange.fromJson(Map<String, dynamic> json) => SyncDateRange(
    DateTime.parse(json['start']),
    DateTime.parse(json['end']),
  );

  @override
  String toString() => '[${start.toIso8601String()} - ${end.toIso8601String()}]';
}

class SyncRangeManager {
  static const String _keyPrefix = 'synced_date_ranges_';

  Future<List<SyncDateRange>> getSyncedRanges(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$_keyPrefix$userId');
    if (jsonStr == null) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => SyncDateRange.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSyncedRanges(String userId, List<SyncDateRange> ranges) async {
    final prefs = await SharedPreferences.getInstance();
    final merged = _mergeRanges(ranges);
    final jsonStr = jsonEncode(merged.map((e) => e.toJson()).toList());
    await prefs.setString('$_keyPrefix$userId', jsonStr);
  }

  Future<void> addSyncedRange(String userId, DateTime start, DateTime end) async {
    final currentRanges = await getSyncedRanges(userId);
    currentRanges.add(SyncDateRange(start, end));
    await saveSyncedRanges(userId, currentRanges);
  }

  List<SyncDateRange> calculateMissingGaps(SyncDateRange requested, List<SyncDateRange> syncedRanges) {
    List<SyncDateRange> gaps = [];
    DateTime currentStart = requested.start;

    // Make sure synced ranges are sorted and merged before checking
    final mergedSynced = _mergeRanges(syncedRanges);

    for (var sync in mergedSynced) {
      if (currentStart.isAfter(requested.end) || currentStart.isAtSameMomentAs(requested.end)) break;
      
      if (sync.end.isBefore(currentStart) || sync.end.isAtSameMomentAs(currentStart)) continue;

      if (sync.start.isAfter(currentStart)) {
        // There is a gap before this sync range
        final endGap = sync.start.isBefore(requested.end) ? sync.start : requested.end;
        gaps.add(SyncDateRange(currentStart, endGap));
      }

      currentStart = sync.end.isAfter(currentStart) ? sync.end : currentStart;
    }

    if (currentStart.isBefore(requested.end)) {
      gaps.add(SyncDateRange(currentStart, requested.end));
    }

    return gaps;
  }

  List<SyncDateRange> _mergeRanges(List<SyncDateRange> ranges) {
    if (ranges.isEmpty) return [];
    
    // Sort by start date
    final sorted = List<SyncDateRange>.from(ranges)
      ..sort((a, b) => a.start.compareTo(b.start));
      
    List<SyncDateRange> merged = [sorted.first];
    
    for (int i = 1; i < sorted.length; i++) {
      final last = merged.last;
      final current = sorted[i];
      
      // If they overlap or are adjacent (we add 1 second grace period for adjacency if needed, but exact time is fine)
      if (!current.start.isAfter(last.end)) {
        final newEnd = current.end.isAfter(last.end) ? current.end : last.end;
        merged.last = SyncDateRange(last.start, newEnd);
      } else {
        merged.add(current);
      }
    }
    
    return merged;
  }
}
