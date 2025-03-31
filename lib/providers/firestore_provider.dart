import 'package:flutter/foundation.dart';
import 'package:expense_tracker/models/user_model.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/budget_model.dart';
import 'package:expense_tracker/models/settings_model.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:expense_tracker/services/auth_service.dart';

class FirestoreProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  List<Transaction>? _transactions;
  List<CategoryModel>? _categories;
  BudgetModel? _currentBudget;
  SettingsModel? _settings;
  
  String? _userId;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  UserModel? get user => _user;
  List<Transaction>? get transactions => _transactions;
  List<CategoryModel>? get categories => _categories;
  BudgetModel? get currentBudget => _currentBudget;
  SettingsModel? get settings => _settings;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  
  // Initialize the provider
  Future<void> initialize() async {
    setLoading(true);
    try {
      // Initialize Firestore persistence
      await _authService.initialize();
      
      // Check if user is already signed in
      String? userId = await _authService.getUserIdFromPrefs();
      if (userId != null) {
        await loadUserData(userId);
      }
    } catch (e) {
      setError('Error initializing Firestore: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // Load user data from Firestore
  Future<void> loadUserData(String userId) async {
    setLoading(true);
    _userId = userId;
    try {
      // Load user
      _user = await _authService.getUserFromFirestore(userId);
      
      // Load user settings
      _settings = await _firestoreService.getUserSettings(userId);
      
      // Load categories
      _categories = await _firestoreService.getAllCategories();
      
      // Load current budget
      _currentBudget = await _firestoreService.getCurrentBudget(userId);
      
      notifyListeners();
      
      // Set up stream for transactions - this will continuously update
      _firestoreService.getUserExpenses(userId).listen((transactions) {
        _transactions = transactions;
        notifyListeners();
      });
    } catch (e) {
      setError('Error loading user data: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    setLoading(true);
    try {
      await _authService.signOut();
      _user = null;
      _transactions = null;
      _categories = null;
      _currentBudget = null;
      _settings = null;
      _userId = null;
      notifyListeners();
    } catch (e) {
      setError('Error signing out: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // Add a transaction
  Future<void> addTransaction(Transaction transaction) async {
    if (_userId == null) {
      setError('User not authenticated');
      return;
    }
    
    setLoading(true);
    try {
      // Add userId to transaction if not already present
      if (transaction.userId.isEmpty) {
        transaction = Transaction(
          userId: _userId!,
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
      
      await _firestoreService.addExpense(transaction);
      // No need to update _transactions as the stream will handle that
    } catch (e) {
      setError('Error adding transaction: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // Update a transaction
  Future<void> updateTransaction(Transaction transaction) async {
    setLoading(true);
    try {
      await _firestoreService.updateExpense(transaction);
      // No need to update _transactions as the stream will handle that
    } catch (e) {
      setError('Error updating transaction: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    setLoading(true);
    try {
      await _firestoreService.deleteExpense(transactionId);
      // No need to update _transactions as the stream will handle that
    } catch (e) {
      setError('Error deleting transaction: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // Add or update a category
  Future<void> saveCategory(CategoryModel category) async {
    setLoading(true);
    try {
      await _firestoreService.saveCategory(category);
      
      // Update the categories list
      _categories = await _firestoreService.getAllCategories();
      notifyListeners();
    } catch (e) {
      setError('Error saving category: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // Create or update a budget
  Future<void> saveBudget(BudgetModel budget) async {
    setLoading(true);
    try {
      if (budget.id.isEmpty) {
        // Create new budget
        String budgetId = await _firestoreService.createBudget(budget);
        _currentBudget = BudgetModel(
          id: budgetId,
          userId: budget.userId,
          amount: budget.amount,
          period: budget.period,
          startDate: budget.startDate,
          endDate: budget.endDate,
          categories: budget.categories,
          notes: budget.notes,
        );
      } else {
        // Update existing budget
        await _firestoreService.updateBudget(budget);
        _currentBudget = budget;
      }
      notifyListeners();
    } catch (e) {
      setError('Error saving budget: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // Update user settings
  Future<void> updateSettings(SettingsModel settings) async {
    setLoading(true);
    try {
      await _firestoreService.updateUserSettings(settings);
      _settings = settings;
      notifyListeners();
    } catch (e) {
      setError('Error updating settings: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // Helper methods
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 