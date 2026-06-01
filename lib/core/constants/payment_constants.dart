import 'package:flutter/material.dart';

class BankModel {
  final String id;
  final String name;

  const BankModel({
    required this.id,
    required this.name,
  });
}

class PaymentMethodModel {
  final String id;
  final String name;
  final IconData icon;

  const PaymentMethodModel({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class PaymentConstants {
  static const List<BankModel> indianBanks = [
    BankModel(id: 'axis_bank', name: 'Axis Bank'),
    BankModel(id: 'bank_of_baroda', name: 'Bank of Baroda'),
    BankModel(id: 'bank_of_india', name: 'Bank of India'),
    BankModel(id: 'bank_of_maharashtra', name: 'Bank of Maharashtra'),
    BankModel(id: 'canara_bank', name: 'Canara Bank'),
    BankModel(id: 'central_bank_of_india', name: 'Central Bank of India'),
    BankModel(id: 'city_union_bank', name: 'City Union Bank'),
    BankModel(id: 'federal_bank', name: 'Federal Bank'),
    BankModel(id: 'hdfc_bank', name: 'HDFC Bank'),
    BankModel(id: 'icici_bank', name: 'ICICI Bank'),
    BankModel(id: 'idbi_bank', name: 'IDBI Bank'),
    BankModel(id: 'idfc_first_bank', name: 'IDFC First Bank'),
    BankModel(id: 'indian_bank', name: 'Indian Bank'),
    BankModel(id: 'indian_overseas_bank', name: 'Indian Overseas Bank'),
    BankModel(id: 'indusind_bank', name: 'IndusInd Bank'),
    BankModel(id: 'jammu_kashmir_bank', name: 'Jammu & Kashmir Bank'),
    BankModel(id: 'karnataka_bank', name: 'Karnataka Bank'),
    BankModel(id: 'karur_vysya_bank', name: 'Karur Vysya Bank'),
    BankModel(id: 'kotak_mahindra_bank', name: 'Kotak Mahindra Bank'),
    BankModel(id: 'punjab_sind_bank', name: 'Punjab & Sind Bank'),
    BankModel(id: 'punjab_national_bank', name: 'Punjab National Bank'),
    BankModel(id: 'rbl_bank', name: 'RBL Bank'),
    BankModel(id: 'south_indian_bank', name: 'South Indian Bank'),
    BankModel(id: 'sbi', name: 'State Bank of India (SBI)'),
    BankModel(id: 'uco_bank', name: 'UCO Bank'),
    BankModel(id: 'union_bank_of_india', name: 'Union Bank of India'),
    BankModel(id: 'yes_bank', name: 'Yes Bank'),
  ];

  static const List<PaymentMethodModel> paymentMethods = [
    PaymentMethodModel(
      id: 'upi',
      name: 'UPI',
      icon: Icons.qr_code_scanner_rounded,
    ),
    PaymentMethodModel(
      id: 'debit_card',
      name: 'Debit Card',
      icon: Icons.credit_card_rounded,
    ),
    PaymentMethodModel(
      id: 'credit_card',
      name: 'Credit Card',
      icon: Icons.payment_rounded,
    ),
    PaymentMethodModel(
      id: 'cash',
      name: 'Cash',
      icon: Icons.payments_rounded,
    ),
    PaymentMethodModel(
      id: 'net_banking',
      name: 'Net Banking',
      icon: Icons.account_balance_rounded,
    ),
    PaymentMethodModel(
      id: 'wallet',
      name: 'Wallet',
      icon: Icons.account_balance_wallet_rounded,
    ),
  ];

  /// Resolves display name for a bank ID
  static String getBankName(String? id) {
    if (id == null || id.isEmpty) return 'Select Bank';
    if (id.startsWith('custom:')) {
      return id.substring(7);
    }
    final bank = indianBanks.firstWhere(
      (b) => b.id == id,
      orElse: () => BankModel(id: id, name: id),
    );
    return bank.name;
  }

  /// Resolves display name for a payment method ID
  static String getPaymentMethodName(String? id) {
    if (id == null || id.isEmpty) return 'Select Payment';
    if (id.startsWith('custom:')) {
      return id.substring(7);
    }
    final method = paymentMethods.firstWhere(
      (p) => p.id == id,
      orElse: () => PaymentMethodModel(
        id: id,
        name: id,
        icon: Icons.help_outline_rounded,
      ),
    );
    return method.name;
  }

  /// Resolves icon for a payment method ID
  static IconData getPaymentMethodIcon(String? id) {
    if (id == null || id.isEmpty) return Icons.payment_rounded;
    if (id.startsWith('custom:')) return Icons.edit_note_rounded;
    final method = paymentMethods.firstWhere(
      (p) => p.id == id,
      orElse: () => PaymentMethodModel(
        id: id,
        name: id,
        icon: Icons.payment_rounded,
      ),
    );
    return method.icon;
  }
}
