import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction_model.dart' as model;
import 'package:expense_tracker/services/transaction_service.dart';
import 'package:intl/intl.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  
  List<model.Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  
  // Getters
  List<model.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;
  
  // Computed properties
  int get selectedYear => _selectedDate.year;
  int get selectedMonth => _selectedDate.month;
  String get formattedMonth => DateFormat('MMMM yyyy').format(_selectedDate);
  
  List<model.Transaction> get incomeTransactions => 
      _transactions.where((t) => t.type == model.TransactionType.income).toList();
  
  List<model.Transaction> get expenseTransactions => 
      _transactions.where((t) => t.type == model.TransactionType.expense).toList();
  
  double get totalIncome {
    double total = 0;
    for (var transaction in incomeTransactions) {
      total += transaction.amount;
    }
    return total;
  }
  
  double get totalExpense {
    double total = 0;
    for (var transaction in expenseTransactions) {
      total += transaction.amount;
    }
    return total;
  }
  
  double get balance => totalIncome - totalExpense;
  
  // Initialize transactions
  Future<void> initTransactions() async {
    await fetchTransactionsByMonth(selectedYear, selectedMonth);
  }
  
  // Change selected month
  void changeMonth(int offset) {
    final newDate = DateTime(selectedYear, selectedMonth + offset);
    _selectedDate = newDate;
    fetchTransactionsByMonth(newDate.year, newDate.month);
  }
  
  // Fetch transactions by month
  Future<void> fetchTransactionsByMonth(int year, int month) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _transactions = await _transactionService.getTransactionsByMonth(year, month);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add a new transaction
  Future<void> addTransaction(model.Transaction transaction) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _transactionService.addTransaction(transaction);
      await fetchTransactionsByMonth(selectedYear, selectedMonth);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Update transaction
  Future<void> updateTransaction(model.Transaction transaction) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _transactionService.updateTransaction(transaction);
      await fetchTransactionsByMonth(selectedYear, selectedMonth);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _transactionService.deleteTransaction(id);
      await fetchTransactionsByMonth(selectedYear, selectedMonth);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Delete all transactions
  Future<void> deleteAllTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _transactionService.deleteAllTransactions();
      await fetchTransactionsByMonth(selectedYear, selectedMonth);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Get expense category totals for charts
  Future<Map<String, double>> getExpenseCategoryTotals() async {
    try {
      return await _transactionService.getExpenseCategoryTotals(selectedYear, selectedMonth);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }
  
  // Get income category totals for charts
  Future<Map<String, double>> getIncomeCategoryTotals() async {
    try {
      return await _transactionService.getIncomeCategoryTotals(selectedYear, selectedMonth);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 