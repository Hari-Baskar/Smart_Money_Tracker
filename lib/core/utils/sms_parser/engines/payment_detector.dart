class PaymentDetector {
  /// Detects the bank ID from the Sender ID (header) or SMS body
  static String? detectBank(String sender, String normalizedBody) {
    final senderUpper = sender.toUpperCase();
    final bodyLower = normalizedBody.toLowerCase();

    // 1. Analyze the Sender ID first (High Speed & 95% accurate)
    // Transactional SMS headers in India end with a bank code (e.g. AD-HDFCBK, VK-SBIINB)
    if (senderUpper.contains('HDFC') || senderUpper.contains('HDFCTX')) {
      return 'hdfc_bank';
    }
    if (senderUpper.contains('SBI') || senderUpper.contains('SBIPSG') || senderUpper.contains('SBIINB')) {
      return 'sbi';
    }
    if (senderUpper.contains('ICICI') || senderUpper.contains('ICICIB') || senderUpper.contains('ICICIP')) {
      return 'icici_bank';
    }
    if (senderUpper.contains('AXIS') || senderUpper.contains('AXISBK')) {
      return 'axis_bank';
    }
    if (senderUpper.contains('KOTAK') || senderUpper.contains('KOTAKB')) {
      return 'kotak_mahindra_bank';
    }
    if (senderUpper.contains('PNB') || senderUpper.contains('PNBSMS') || senderUpper.contains('PUNJAB')) {
      return 'punjab_national_bank';
    }
    if (senderUpper.contains('CANARA') || senderUpper.contains('CNRB')) {
      return 'canara_bank';
    }
    if (senderUpper.contains('BARODA') || senderUpper.contains('BOB')) {
      return 'bank_of_baroda';
    }
    if (senderUpper.contains('BOI') || senderUpper.contains('BOISMS')) {
      return 'bank_of_india';
    }
    if (senderUpper.contains('MAHSMS') || senderUpper.contains('BOM')) {
      return 'bank_of_maharashtra';
    }
    if (senderUpper.contains('FEDRL') || senderUpper.contains('FDRL') || senderUpper.contains('FEDERAL')) {
      return 'federal_bank';
    }
    if (senderUpper.contains('IDFC') || senderUpper.contains('IDFCBK')) {
      return 'idfc_first_bank';
    }
    if (senderUpper.contains('INDUS') || senderUpper.contains('INDUSB')) {
      return 'indusind_bank';
    }
    if (senderUpper.contains('YES') || senderUpper.contains('YESBNK')) {
      return 'yes_bank';
    }
    if (senderUpper.contains('KVB') || senderUpper.contains('KVBLTD')) {
      return 'karur_vysya_bank';
    }
    if (senderUpper.contains('RBL') || senderUpper.contains('RBLBK')) {
      return 'rbl_bank';
    }
    if (senderUpper.contains('SIB') || senderUpper.contains('SIBSMS')) {
      return 'south_indian_bank';
    }
    if (senderUpper.contains('UNIONB') || senderUpper.contains('UBI')) {
      return 'union_bank_of_india';
    }
    if (senderUpper.contains('UCO') || senderUpper.contains('UCOBK')) {
      return 'uco_bank';
    }
    if (senderUpper.contains('INDIAN') || senderUpper.contains('IDN')) {
      return 'indian_bank';
    }
    if (senderUpper.contains('IOB')) {
      return 'indian_overseas_bank';
    }
    if (senderUpper.contains('CUB')) {
      return 'city_union_bank';
    }
    if (senderUpper.contains('IDBI') || senderUpper.contains('IDBIBK')) {
      return 'idbi_bank';
    }
    if (senderUpper.contains('JKB')) {
      return 'jammu_kashmir_bank';
    }
    if (senderUpper.contains('KTK') || senderUpper.contains('KBL')) {
      return 'karnataka_bank';
    }

    // 2. Scan body keywords (Fallback if Sender ID is generic or promotional)
    if (bodyLower.contains('hdfc bank') || bodyLower.contains('hdfc')) {
      return 'hdfc_bank';
    }
    if (bodyLower.contains('state bank') || bodyLower.contains('sbi') || bodyLower.contains('sbi card')) {
      return 'sbi';
    }
    if (bodyLower.contains('icici bank') || bodyLower.contains('icici')) {
      return 'icici_bank';
    }
    if (bodyLower.contains('axis bank') || bodyLower.contains('axis')) {
      return 'axis_bank';
    }
    if (bodyLower.contains('kotak bank') || bodyLower.contains('kotak')) {
      return 'kotak_mahindra_bank';
    }
    if (bodyLower.contains('punjab national') || bodyLower.contains('pnb')) {
      return 'punjab_national_bank';
    }
    if (bodyLower.contains('canara bank') || bodyLower.contains('canara')) {
      return 'canara_bank';
    }
    if (bodyLower.contains('bank of baroda') || bodyLower.contains('bob')) {
      return 'bank_of_baroda';
    }
    if (bodyLower.contains('bank of india') || bodyLower.contains('boi')) {
      return 'bank_of_india';
    }
    if (bodyLower.contains('bank of maharashtra') || bodyLower.contains('mahabank')) {
      return 'bank_of_maharashtra';
    }
    if (bodyLower.contains('federal bank') || bodyLower.contains('fedbank')) {
      return 'federal_bank';
    }
    if (bodyLower.contains('idfc bank') || bodyLower.contains('idfc first') || bodyLower.contains('idfc')) {
      return 'idfc_first_bank';
    }
    if (bodyLower.contains('indusind bank') || bodyLower.contains('indusind')) {
      return 'indusind_bank';
    }
    if (bodyLower.contains('yes bank') || bodyLower.contains('yesbnk')) {
      return 'yes_bank';
    }
    if (bodyLower.contains('karur vysya') || bodyLower.contains('kvb')) {
      return 'karur_vysya_bank';
    }
    if (bodyLower.contains('rbl bank') || bodyLower.contains('rbl')) {
      return 'rbl_bank';
    }
    if (bodyLower.contains('south indian bank') || bodyLower.contains('sib ')) {
      return 'south_indian_bank';
    }
    if (bodyLower.contains('union bank') || bodyLower.contains('union bank of india')) {
      return 'union_bank_of_india';
    }
    if (bodyLower.contains('uco bank')) {
      return 'uco_bank';
    }
    if (bodyLower.contains('indian bank')) {
      return 'indian_bank';
    }
    if (bodyLower.contains('indian overseas bank') || bodyLower.contains('iob ')) {
      return 'indian_overseas_bank';
    }
    if (bodyLower.contains('city union bank') || bodyLower.contains('cub ')) {
      return 'city_union_bank';
    }
    if (bodyLower.contains('idbi bank') || bodyLower.contains('idbi')) {
      return 'idbi_bank';
    }
    if (bodyLower.contains('j&k bank') || bodyLower.contains('jammu & kashmir') || bodyLower.contains('jkb ')) {
      return 'jammu_kashmir_bank';
    }
    if (bodyLower.contains('karnataka bank')) {
      return 'karnataka_bank';
    }

    return null; // Return null if bank cannot be auto-detected
  }

  /// Detects the payment method ID from the Sender ID (header) and SMS body
  static String? detectPaymentMethod(String sender, String normalizedBody) {
    final senderUpper = sender.toUpperCase();
    final bodyLower = normalizedBody.toLowerCase();

    // 1. Digital Wallet Checks (high specificity)
    if (bodyLower.contains('wallet') ||
        bodyLower.contains('paytm wallet') ||
        bodyLower.contains('amazon pay') ||
        bodyLower.contains('mobikwik') ||
        bodyLower.contains('added to wallet') ||
        bodyLower.contains('wallet balance')) {
      return 'wallet';
    }

    // 2. Credit Card Checks (high specificity sender & body keywords)
    if (senderUpper.contains('CARD') ||
        senderUpper.contains('CRD') ||
        senderUpper.contains('SBICRD') ||
        senderUpper.contains('HDFCCRD') ||
        senderUpper.contains('ICICICC') ||
        senderUpper.contains('AXISCR') ||
        senderUpper.contains('AMEX') ||
        senderUpper.contains('AMERICANEXPRESS')) {
      // It's a card sender, check if it's credit or debit
      if (bodyLower.contains('debit') || bodyLower.contains('dc')) {
        return 'debit_card';
      }
      return 'credit_card';
    }

    if (bodyLower.contains('credit card') ||
        bodyLower.contains('spent on cc') ||
        bodyLower.contains('spent on credit') ||
        bodyLower.contains('cc ending') ||
        bodyLower.contains('c-card') ||
        bodyLower.contains('creditcard') ||
        (bodyLower.contains('card ending') &&
            (bodyLower.contains('statement') ||
                bodyLower.contains('due') ||
                bodyLower.contains('limit') ||
                bodyLower.contains('available limit') ||
                bodyLower.contains('minimum due')))) {
      return 'credit_card';
    }

    // 3. Debit Card / ATM / POS Checks
    if (bodyLower.contains('debit card') ||
        bodyLower.contains('spent on debit') ||
        bodyLower.contains('atm cash') ||
        bodyLower.contains('cash withdrawal') ||
        bodyLower.contains('dispensed') ||
        bodyLower.contains('spent on db') ||
        bodyLower.contains('db card') ||
        bodyLower.contains('debit card ending') ||
        bodyLower.contains('dcard') ||
        bodyLower.contains('withdrawn at atm') ||
        bodyLower.contains('atm txn') ||
        bodyLower.contains('pos txn') ||
        bodyLower.contains('at pos') ||
        bodyLower.contains('pos transaction')) {
      return 'debit_card';
    }

    // 4. UPI Checks (including Sender ID, VPA handles, 12-digit references)
    // A. Check Sender ID for UPI providers
    if (senderUpper.contains('PAYTM') ||
        senderUpper.contains('GPAY') ||
        senderUpper.contains('PHONEPE') ||
        senderUpper.contains('BHIM') ||
        senderUpper.contains('UPI')) {
      return 'upi';
    }

    // B. Check VPA handle pattern (e.g. contains @ybl, @upi, @okaxis, or just @ with a word after it)
    final hasVpaHandle = RegExp(r'@[a-zA-Z]{2,}').hasMatch(bodyLower);
    
    // C. Check 12-digit UPI / IMPS Ref number in transactional context
    final has12DigitRef = RegExp(r'\b\d{12}\b').hasMatch(bodyLower) && 
        (bodyLower.contains('ref') || 
         bodyLower.contains('utr') || 
         bodyLower.contains('upi') || 
         bodyLower.contains('txn') ||
         bodyLower.contains('transaction') ||
         bodyLower.contains('transfer') ||
         bodyLower.contains('sent') ||
         bodyLower.contains('paid') ||
         bodyLower.contains('debited') ||
         bodyLower.contains('credited'));

    if (bodyLower.contains('upi') ||
        bodyLower.contains('vpa') ||
        bodyLower.contains('gpay') ||
        bodyLower.contains('googlepay') ||
        bodyLower.contains('phonepe') ||
        bodyLower.contains('paytm') ||
        bodyLower.contains('bhim') ||
        bodyLower.contains('upi ref') ||
        bodyLower.contains('credited via upi') ||
        hasVpaHandle ||
        has12DigitRef) {
      return 'upi';
    }

    // 5. Net Banking / Electronic Transfers
    if (bodyLower.contains('netbanking') ||
        bodyLower.contains('net banking') ||
        bodyLower.contains('internet banking') ||
        bodyLower.contains('neft') ||
        bodyLower.contains('rtgs') ||
        bodyLower.contains('imps') ||
        bodyLower.contains('transferred via')) {
      return 'net_banking';
    }

    return null; // Return null if payment method cannot be auto-detected
  }
}
