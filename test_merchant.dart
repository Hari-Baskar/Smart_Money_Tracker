import "package:smart_money_tracker/core/utils/sms_parser/engines/rule_extraction_engine.dart";
import "package:smart_money_tracker/core/utils/sms_parser.dart";

void main() async {
  String sms = "Rs.2977.00 Debited to SB-xxx7502 AcBal:2061.86 CLRBal: 2061.86 [To: INSTIT ] MARUNGAPURI on 13-11-2025 11:18:40.IOB observes VAW 2025.";
  print("RuleEngine Merchant: ${RuleExtractionEngine.extractMerchant(sms, "IOB")}");
  
  final txn = await SmsParser.parse(sms, "IOB");
  print("SmsParser Merchant: ${txn?.merchant}");
}
