import 'package:expense_tracker/database/database_helper.dart';
import 'package:expense_tracker/models/transaction_model.dart' as model;

class TransactionService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  
  Future<String> addTransaction(model.Transaction transaction) async {
    return await _databaseHelper.insertTransaction(transaction);
  }
  
  Future<int> updateTransaction(model.Transaction transaction) async {
    return await _databaseHelper.updateTransaction(transaction);
  }
  
  Future<int> deleteTransaction(String id) async {
    return await _databaseHelper.deleteTransaction(id);
  }
  
  Future<List<model.Transaction>> getAllTransactions() async {
    return await _databaseHelper.getTransactions();
  }
  
  Future<List<model.Transaction>> getTransactionsByMonth(int year, int month) async {
    return await _databaseHelper.getTransactionsByMonth(year, month);
  }
  
  Future<double> getTotalIncome(int year, int month) async {
    return await _databaseHelper.getTotalAmount(model.TransactionType.income, year, month);
  }
  
  Future<double> getTotalExpense(int year, int month) async {
    return await _databaseHelper.getTotalAmount(model.TransactionType.expense, year, month);
  }
  
  Future<Map<String, double>> getExpenseCategoryTotals(int year, int month) async {
    return await _databaseHelper.getCategoryTotals(model.TransactionType.expense, year, month);
  }
  
  Future<Map<String, double>> getIncomeCategoryTotals(int year, int month) async {
    return await _databaseHelper.getCategoryTotals(model.TransactionType.income, year, month);
  }
  
  Future<void> deleteAllTransactions() async {
    await _databaseHelper.deleteAllTransactions();
  }
} 