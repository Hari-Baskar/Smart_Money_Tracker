import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../state/settings_state.dart';
import '../notifiers/settings_notifier.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
