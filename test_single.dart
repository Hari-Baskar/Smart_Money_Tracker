import 'lib/core/utils/sms_parser/engines/financial_detector.dart';

void main() {
  String sms = "Dear 82207XX, Rs.2,000 to Rs. 80,000* loan can be credited to your Bank A/c on 21.07.2026. Check if you qualify: http://hu2.in/RFcrp/yxYc3q - Ram Fincor";
  bool isFinancial = FinancialDetector.isFinancialSms(sms, 'TEST_SENDER');
  print('Result isFinancial: ');
  print(isFinancial);
}
