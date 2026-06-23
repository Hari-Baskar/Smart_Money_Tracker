import 'package:flutter_test/flutter_test.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';

void main() {
  group('AppColors.formatShortAmount Tests', () {
    test('less than 1000', () {
      expect(AppColors.formatShortAmount(0), '0');
      expect(AppColors.formatShortAmount(50), '50');
      expect(AppColors.formatShortAmount(950), '950');
      expect(AppColors.formatShortAmount(999.9), '999.9');
      expect(AppColors.formatShortAmount(-250), '-250');
    });

    test('thousands (K)', () {
      expect(AppColors.formatShortAmount(1000), '1K');
      expect(AppColors.formatShortAmount(1200), '1.2K');
      expect(AppColors.formatShortAmount(1250), '1.25K');
      expect(AppColors.formatShortAmount(1256.78), '1.26K');
      expect(AppColors.formatShortAmount(10000), '10K');
      expect(AppColors.formatShortAmount(12500), '12.5K');
      expect(AppColors.formatShortAmount(100000), '100K');
      expect(AppColors.formatShortAmount(-1250), '-1.25K');
    });

    test('millions (M)', () {
      expect(AppColors.formatShortAmount(1000000), '1M');
      expect(AppColors.formatShortAmount(1250000), '1.25M');
      expect(AppColors.formatShortAmount(10000000), '10M'); // 1 Crore
      expect(AppColors.formatShortAmount(12500000), '12.5M');
      expect(AppColors.formatShortAmount(100000000), '100M'); // 10 Crore
    });

    test('billions (B) / 100 Crore', () {
      expect(AppColors.formatShortAmount(1000000000), '1B'); // 100 Crore
      expect(AppColors.formatShortAmount(1250000000), '1.25B');
      expect(AppColors.formatShortAmount(100000000000), '100B');
    });

    test('trillions (T)', () {
      expect(AppColors.formatShortAmount(1000000000000), '1T');
      expect(AppColors.formatShortAmount(1250000000000), '1.25T');
    });

    test('beyond trillions (Qa, Qi, etc.)', () {
      expect(AppColors.formatShortAmount(1000000000000000), '1Qa');
      expect(AppColors.formatShortAmount(1250000000000000), '1.25Qa');
      expect(AppColors.formatShortAmount(1000000000000000000), '1Qi');
      expect(AppColors.formatShortAmount(1.0098e20), '101Qi');
      expect(AppColors.formatShortAmount(123.45e15), '123Qa');
      expect(AppColors.formatShortAmount(12.345e15), '12.3Qa');
    });
  });
}
