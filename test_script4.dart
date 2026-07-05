import 'lib/core/utils/sms_parser/engines/rule_extraction_engine.dart';
import 'lib/core/utils/sms_parser/engines/financial_detector.dart';

void main() {
  String sms = "Your a/c no. XXXXX02 is credited by Rs.80.00 on 2026-07-05 08:58:18.522, from S N GOKUL NATH-8072726313-1@nyes(UPI Ref no 003195315707).Payer Remark - Paid via Navi UPI -IOB";
  String lower = sms.toLowerCase();
  
  bool isFin = FinancialDetector.isFinancialSms(lower, "VK-IOBBK");
  String type = RuleExtractionEngine.extractType(lower);
  double? amt = RuleExtractionEngine.extractAmount(lower);
  
  print("Is Financial: $isFin");
  print("Type: $type");
  print("Amount: $amt");
}
