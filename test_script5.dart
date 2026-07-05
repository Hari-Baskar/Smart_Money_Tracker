import 'lib/core/utils/sms_parser.dart';

void main() async {
  String sms = "Your a/c no. XXXXX02 is credited by Rs.80.00 on 2026-07-05 08:58:18.522, from S N GOKUL NATH-8072726313-1@nyes(UPI Ref no 003195315707).Payer Remark - Paid via Navi UPI -IOB";
  final result = await SmsParser.parse(sms, "VK-IOBBK");
  
  if (result != null) {
    print("Type: ${result.type.toString()}");
    print("Category: ${result.category}");
    print("Merchant: ${result.merchant}");
  } else {
    print("Parsing failed.");
  }
}
