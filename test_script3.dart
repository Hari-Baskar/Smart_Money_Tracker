void main() {
  const sms = "Recharge Jio no. 9363536606 with Rs.899 plan & enjoy Special benefits:Free Pro Google Gemini worth Rs.35100 + JioHotstar+ Unlimited 5G data + 2 GB/day & 20GB , Unlimited Voice, 90 Days. Use PayZapp & Code: PZPREPAID to get upto Rs.21 back. T&C A. https://payzapp.onelink.me/92W8/iwkkplth";
  
  String text = sms.toLowerCase();
  text = text.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
  text = text.replaceAll(RegExp(r'\s{2,}'), ' ');
  text = text.replaceAll('₹', 'rs ');
  text = text.replaceAll('inr', 'rs ');
  text = text.replaceAll(RegExp(r'[`´‘’]'), "'");
  text = text.replaceAll(RegExp(r'[“”]'), '"');
  text = text.trim();
  
  [
    'debited', 'spent', 'paid', 'payed', 'sent', 
    'transferred', 'transfer', 'withdrawn', 'txn', 'payment', 
    'towards', 'vpa', 'transaction', 'purchase', 'purchased',
    'charge', 'charged', 'payee', 'dr', 'withdrawal', 'pos', 'ecom', 'upi', 'imps', 'neft', 'rtgs'
  ].forEach((kw) {
    if (RegExp(r'\b' + kw + r'\b').hasMatch(text)) {
      print("Debit keyword match: " + kw);
    }
  });
}
