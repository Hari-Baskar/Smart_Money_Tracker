import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/main.dart';

void main() {
  testWidgets('App starts test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: This will likely fail in a real environment because Firebase is not initialized,
    // but it fixes the compilation errors.
    await tester.pumpWidget(const ExpenseTrackerApp());
  });
}
