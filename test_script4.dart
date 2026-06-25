void main() {
  const sms = "Recharge Jio no. 9363536606 with Rs.899 plan & enjoy Special benefits:Free Pro Google Gemini worth Rs.35100 + JioHotstar+ Unlimited 5G data + 2 GB/day & 20GB , Unlimited Voice, 90 Days. Use PayZapp & Code: PZPREPAID to get upto Rs.21 back. T&C A. https://payzapp.onelink.me/92W8/iwkkplth";
  
  String text = sms.toLowerCase();
  
  final _promotionalRegex = RegExp(
    r'(?:up\s*to|win|earn|save|get|chance to|valid till)\s+(?:flat|free|extra|up\s*to\s+)?(?:rs\.?|inr|₹)\s*\d+', 
    caseSensitive: false
  );
  
  print("Regex match: \${_promotionalRegex.hasMatch(text)}");
}
