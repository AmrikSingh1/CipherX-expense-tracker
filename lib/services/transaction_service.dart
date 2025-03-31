import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/services/firestore_service.dart';

class TransactionService {
  final FirestoreService _firestoreService = FirestoreService();
  
  Future<String> addTransaction(Transaction transaction) async {
    return await _firestoreService.addExpense(transaction);
  }
  
  Future<void> updateTransaction(Transaction transaction) async {
    await _firestoreService.updateExpense(transaction);
  }
  
  Future<void> deleteTransaction(String id) async {
    await _firestoreService.deleteExpense(id);
  }
  
  Stream<List<Transaction>> getAllTransactions(String userId) {
    return _firestoreService.getUserExpenses(userId);
  }
  
  Stream<List<Transaction>> getTransactionsByMonth(String userId, int year, int month) {
    return _firestoreService.getExpensesByMonth(userId, year, month);
  }
  
  Future<double> getTotalIncome(String userId, int year, int month) async {
    return await _firestoreService.getTotalIncome(userId, year, month);
  }
  
  Future<double> getTotalExpense(String userId, int year, int month) async {
    return await _firestoreService.getTotalExpense(userId, year, month);
  }
  
  Future<Map<String, double>> getExpenseCategoryTotals(String userId, int year, int month) async {
    return await _firestoreService.getExpenseCategoryTotals(userId, year, month);
  }
  
  Future<Map<String, double>> getIncomeCategoryTotals(String userId, int year, int month) async {
    // This would need to be implemented in the FirestoreService
    // For now, return an empty map
    return {};
  }
} 