import 'package:flutter_test/flutter_test.dart';
import 'package:smart_money_tracker/core/models/budget_model.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/budget/domain/providers/budget_providers.dart';

void main() {
  group('Budget Split Transactions calculation', () {
    test('filters only matching split item for category budget', () {
      final foodBudget = BudgetModel(
        id: 'b_food',
        name: 'Food Budget',
        amount: 5000,
        categoryId: 'food',
        period: BudgetPeriod.monthly,
      );

      final shoppingBudget = BudgetModel(
        id: 'b_shopping',
        name: 'Shopping Budget',
        amount: 10000,
        categoryId: 'shopping',
        period: BudgetPeriod.monthly,
      );

      // Total ₹1000: ₹300 Food, ₹700 Shopping
      final splitTxn = TransactionModel(
        id: 'tx_split_1',
        amount: 1000,
        merchant: 'Supermart',
        date: DateTime(2026, 9, 15),
        type: TransactionType.debit,
        category: 'shopping',
        subcategory: '',
        rawSms: 'Test SMS',
        splits: [
          TransactionSplit(
            amount: 300,
            category: 'food',
            subcategory: 'Groceries',
          ),
          TransactionSplit(
            amount: 700,
            category: 'shopping',
            subcategory: 'Clothes',
          ),
        ],
      );

      final foodTxns = getApplicableTransactionsForBudget(foodBudget, [splitTxn]);
      final shoppingTxns = getApplicableTransactionsForBudget(shoppingBudget, [splitTxn]);

      // Food budget should only take the ₹300 split portion
      expect(foodTxns.length, 1);
      expect(foodTxns.first.amount, 300);
      expect(foodTxns.first.category, 'food');
      expect(foodTxns.first.subcategory, 'Groceries');
      expect(foodTxns.first.id, 'tx_split_1_split_0');

      // Shopping budget should only take the ₹700 split portion
      expect(shoppingTxns.length, 1);
      expect(shoppingTxns.first.amount, 700);
      expect(shoppingTxns.first.category, 'shopping');
      expect(shoppingTxns.first.subcategory, 'Clothes');
      expect(shoppingTxns.first.id, 'tx_split_1_split_1');
    });

    test('handles remainder properly when split sum is less than total', () {
      final foodBudget = BudgetModel(
        id: 'b_food',
        name: 'Food Budget',
        amount: 5000,
        categoryId: 'food',
        period: BudgetPeriod.monthly,
      );

      final travelBudget = BudgetModel(
        id: 'b_travel',
        name: 'Travel Budget',
        amount: 3000,
        categoryId: 'travel',
        period: BudgetPeriod.monthly,
      );

      // Base category is Food (Total ₹1000), but split has ₹400 for Travel, leaving ₹600 remainder in Food
      final splitTxn = TransactionModel(
        id: 'tx_split_2',
        amount: 1000,
        merchant: 'Transit Mart',
        date: DateTime(2026, 9, 15),
        type: TransactionType.debit,
        category: 'food',
        subcategory: 'Snacks',
        rawSms: 'Test SMS',
        splits: [
          TransactionSplit(
            amount: 400,
            category: 'travel',
            subcategory: 'Cab',
          ),
        ],
      );

      final foodTxns = getApplicableTransactionsForBudget(foodBudget, [splitTxn]);
      final travelTxns = getApplicableTransactionsForBudget(travelBudget, [splitTxn]);

      // Travel gets ₹400
      expect(travelTxns.length, 1);
      expect(travelTxns.first.amount, 400);
      expect(travelTxns.first.category, 'travel');

      // Food gets ₹600 remainder
      expect(foodTxns.length, 1);
      expect(foodTxns.first.amount, 600);
      expect(foodTxns.first.category, 'food');
      expect(foodTxns.first.id, 'tx_split_2_remainder');
    });

    test('handles subcategory specific budgets', () {
      final groceriesBudget = BudgetModel(
        id: 'b_groceries',
        name: 'Groceries Budget',
        amount: 3000,
        categoryId: 'food',
        subcategoryId: 'Groceries',
        period: BudgetPeriod.monthly,
      );

      final diningBudget = BudgetModel(
        id: 'b_dining',
        name: 'Dining Budget',
        amount: 2000,
        categoryId: 'food',
        subcategoryId: 'Dining Out',
        period: BudgetPeriod.monthly,
      );

      final splitTxn = TransactionModel(
        id: 'tx_split_3',
        amount: 800,
        merchant: 'Market & Cafe',
        date: DateTime(2026, 9, 15),
        type: TransactionType.debit,
        category: 'food',
        subcategory: '',
        rawSms: 'Test SMS',
        splits: [
          TransactionSplit(
            amount: 500,
            category: 'food',
            subcategory: 'Groceries',
          ),
          TransactionSplit(
            amount: 300,
            category: 'food',
            subcategory: 'Dining Out',
          ),
        ],
      );

      final grocTxns = getApplicableTransactionsForBudget(groceriesBudget, [splitTxn]);
      final dinTxns = getApplicableTransactionsForBudget(diningBudget, [splitTxn]);

      expect(grocTxns.length, 1);
      expect(grocTxns.first.amount, 500);

      expect(dinTxns.length, 1);
      expect(dinTxns.first.amount, 300);
    });
  });
}
