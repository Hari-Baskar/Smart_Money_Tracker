import 'lib/core/utils/sms_parser.dart';

void main() async {
  String sms = "NEFT Inward to A/c No:XX2771,INR:815.38,Ref No:SCBLH21700956950,Rem:GIGAMON SOLUTIONS INDIA PRIVATE LIM,Avl Bal INR 83,017.67 -Pending Verification -KVB";
  var result = await SmsParser.parse(sms, 'TEST_SENDER');
  if (result == null) {
    print("Rejected as non-financial.");
  } else {
    print("Accepted!");
    print("Type: " + result.type.toString());
    print("Amount: " + result.amount.toString());
  }
}
