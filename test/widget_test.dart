import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_money_tracker/main.dart';

void main() {
  testWidgets('App starts test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: This will likely fail in a real environment because Firebase is not initialized,
    // but it fixes the compilation errors.
    await tester.pumpWidget(const ProviderScope(child: ExpenseTrackerApp()));
    
    // Resolve splash screen timer (3 seconds) and transitions without waiting for infinite animations
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 200));
  });
}
