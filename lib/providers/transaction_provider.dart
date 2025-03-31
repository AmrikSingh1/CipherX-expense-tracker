import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction_model.dart' as model;
import 'package:expense_tracker/services/transaction_service.dart';
import 'package:intl/intl.dart';
import 'dart:math' as Math;

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  
  List<model.Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  String _userId = '';
  
  // Getters
  List<model.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;
  
  // Setters
  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }
  
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
  Future<void> initTransactions(String userId) async {
    setUserId(userId);
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
    if (_userId.isEmpty) {
      _error = 'User ID is not set';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('Fetching transactions for user: $_userId, year: $year, month: $month');
      final transactionsStream = _transactionService.getTransactionsByMonth(_userId, year, month);
      
      // Subscribe to the stream to get real-time updates
      transactionsStream.listen(
        (transactions) {
          _transactions = transactions;
          print('Received ${transactions.length} transactions from Firestore');
          
          if (transactions.isNotEmpty) {
            // Log details of the first few transactions for debugging
            for (int i = 0; i < Math.min(3, transactions.length); i++) {
              print('Transaction ${i + 1}: ${transactions[i].title}, '
                  'Amount: ${transactions[i].amount}, '
                  'Date: ${transactions[i].date}, '
                  'ID: ${transactions[i].id}');
            }
          } else {
            print('No transactions found for this month');
          }
          
          _isLoading = false;
          notifyListeners();
        }, 
        onError: (e) {
          print('ERROR fetching transactions: $e');
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        }
      );
    } catch (e) {
      print('EXCEPTION fetching transactions: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add a new transaction
  Future<void> addTransaction(model.Transaction transaction) async {
    print('TransactionProvider.addTransaction called');
    
    if (_userId.isEmpty) {
      _error = 'User ID is not set';
      print('ERROR: $_error');
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Set userId if not already set
      if (transaction.userId.isEmpty) {
        print('Setting user ID for transaction to: $_userId');
        transaction = model.Transaction(
          id: transaction.id,  // Preserve ID if it exists
          userId: _userId,
          title: transaction.title,
          amount: transaction.amount,
          date: transaction.date,
          category: transaction.category,
          type: transaction.type,
          note: transaction.note,
          paymentMethod: transaction.paymentMethod,
          isRecurring: transaction.isRecurring,
          attachmentUrl: transaction.attachmentUrl,
        );
      }
      
      print('Adding transaction to Firestore: ${transaction.title}, Type: ${transaction.type}, Amount: ${transaction.amount}');
      final transactionId = await _transactionService.addTransaction(transaction);
      print('Successfully added transaction with ID: $transactionId');
      
      // No need to fetch transactions again as the stream will update automatically
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('ERROR adding transaction: $_error');
      _isLoading = false;
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
      // No need to fetch transactions again as the stream will update automatically
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
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
      // No need to fetch transactions again as the stream will update automatically
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get expense category totals for charts
  Future<Map<String, double>> getExpenseCategoryTotals() async {
    if (_userId.isEmpty) {
      _error = 'User ID is not set';
      notifyListeners();
      return {};
    }
    
    try {
      return await _transactionService.getExpenseCategoryTotals(_userId, selectedYear, selectedMonth);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }
  
  // Get income category totals for charts
  Future<Map<String, double>> getIncomeCategoryTotals() async {
    if (_userId.isEmpty) {
      _error = 'User ID is not set';
      notifyListeners();
      return {};
    }
    
    try {
      return await _transactionService.getIncomeCategoryTotals(_userId, selectedYear, selectedMonth);
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