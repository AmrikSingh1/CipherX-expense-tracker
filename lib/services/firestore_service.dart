import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/user_model.dart';
import 'package:expense_tracker/models/transaction_model.dart' as transaction_model;
import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/budget_model.dart';
import 'package:expense_tracker/models/income_model.dart';
import 'package:expense_tracker/models/settings_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _expensesCollection => _firestore.collection('expenses');
  CollectionReference get _categoriesCollection => _firestore.collection('categories');
  CollectionReference get _budgetsCollection => _firestore.collection('budgets');
  CollectionReference get _incomesCollection => _firestore.collection('incomes');
  CollectionReference get _settingsCollection => _firestore.collection('settings');
  
  // Configure Firestore for offline persistence
  Future<void> setupPersistence() async {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  
  // Generic error handling wrapper
  Future<T> _handleFirestoreOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      print('Firestore operation failed: ${e.message}');
      throw e;
    } catch (e) {
      print('Unexpected error during Firestore operation: $e');
      throw e;
    }
  }
  
  // USERS COLLECTION OPERATIONS
  
  // Create or update user
  Future<void> saveUser(UserModel user) async {
    return _handleFirestoreOperation(() async {
      await _usersCollection.doc(user.uid).set(user.toMap());
    });
  }
  
  // Get user by ID
  Future<UserModel?> getUser(String uid) async {
    return _handleFirestoreOperation(() async {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
  
  // EXPENSES/TRANSACTIONS COLLECTION OPERATIONS
  
  // Add expense
  Future<String> addExpense(transaction_model.Transaction transaction) async {
    print('FirestoreService.addExpense called');
    return _handleFirestoreOperation(() async {
      // First ensure the transaction data includes the document ID field
      final transactionData = transaction.toFirestore();
      
      // Check if transaction has an ID already
      final String docId = transaction.id;
      print('Using transaction ID: $docId');
      
      // Use the document ID as the Firestore document ID
      DocumentReference docRef = _expensesCollection.doc(docId);
      await docRef.set(transactionData);
      
      print('Transaction saved with ID: ${docRef.id}');
      return docRef.id;
    });
  }
  
  // Update expense
  Future<void> updateExpense(transaction_model.Transaction transaction) async {
    print('FirestoreService.updateExpense called for ID: ${transaction.id}');
    return _handleFirestoreOperation(() async {
      // First ensure the transaction data includes the document ID field
      final transactionData = transaction.toFirestore();
      
      if (transaction.id.isEmpty) {
        print('ERROR: Cannot update transaction with empty ID');
        throw Exception('Transaction ID is empty');
      }
      
      await _expensesCollection.doc(transaction.id).set(transactionData, SetOptions(merge: true));
      print('Transaction updated successfully');
    });
  }
  
  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    return _handleFirestoreOperation(() async {
      await _expensesCollection.doc(expenseId).delete();
    });
  }
  
  // Get all expenses for a user
  Stream<List<transaction_model.Transaction>> getUserExpenses(String userId) {
    return _expensesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => transaction_model.Transaction.fromFirestore(doc))
            .toList());
  }
  
  // Get expenses by month
  Stream<List<transaction_model.Transaction>> getExpensesByMonth(String userId, int year, int month) {
    // Create DateTime objects for the start and end of the month
    DateTime startDate = DateTime(year, month, 1);
    DateTime endDate = DateTime(year, month + 1, 0, 23, 59, 59); // Last day of month
    
    print('Fetching expenses for User: $userId, Year: $year, Month: $month');
    print('Date range: ${startDate.toString()} to ${endDate.toString()}');
    
    // Use a simpler query first to check if any data exists for this user
    return _expensesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Fetched ${snapshot.docs.length} total transactions for user');
          
          List<transaction_model.Transaction> allTransactions = snapshot.docs
            .map((doc) {
              try {
                return transaction_model.Transaction.fromFirestore(doc);
              } catch (e) {
                print('Error parsing transaction document ${doc.id}: $e');
                return null;
              }
            })
            .where((transaction) => transaction != null)
            .cast<transaction_model.Transaction>()
            .toList();
            
          print('Successfully parsed ${allTransactions.length} transactions');
          
          // Filter by date in memory after fetching all documents
          List<transaction_model.Transaction> filteredTransactions = allTransactions
            .where((transaction) => 
                transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
                transaction.date.isBefore(endDate.add(const Duration(days: 1))))
            .toList();
          
          print('Filtered to ${filteredTransactions.length} transactions in date range');
          
          return filteredTransactions;
        });
  }
  
  // CATEGORIES COLLECTION OPERATIONS
  
  // Create or update category
  Future<void> saveCategory(CategoryModel category) async {
    return _handleFirestoreOperation(() async {
      await _categoriesCollection.doc(category.id).set(category.toFirestore());
    });
  }
  
  // Get all categories
  Future<List<CategoryModel>> getAllCategories() async {
    return _handleFirestoreOperation(() async {
      QuerySnapshot snapshot = await _categoriesCollection.get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    });
  }
  
  // Get default categories
  Future<List<CategoryModel>> getDefaultCategories() async {
    return _handleFirestoreOperation(() async {
      QuerySnapshot snapshot = await _categoriesCollection
          .where('isDefault', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    });
  }
  
  // Get user-created categories
  Future<List<CategoryModel>> getUserCategories(String userId) async {
    return _handleFirestoreOperation(() async {
      QuerySnapshot snapshot = await _categoriesCollection
          .where('createdBy', isEqualTo: userId)
          .get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    });
  }
  
  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    return _handleFirestoreOperation(() async {
      await _categoriesCollection.doc(categoryId).delete();
    });
  }
  
  // BUDGETS COLLECTION OPERATIONS
  
  // Create budget
  Future<String> createBudget(BudgetModel budget) async {
    return _handleFirestoreOperation(() async {
      DocumentReference docRef = await _budgetsCollection.add(budget.toFirestore());
      return docRef.id;
    });
  }
  
  // Update budget
  Future<void> updateBudget(BudgetModel budget) async {
    return _handleFirestoreOperation(() async {
      await _budgetsCollection.doc(budget.id).update(budget.toFirestore());
    });
  }
  
  // Get current budget for user
  Future<BudgetModel?> getCurrentBudget(String userId) async {
    return _handleFirestoreOperation(() async {
      // Get the current date
      DateTime now = DateTime.now();
      
      QuerySnapshot snapshot = await _budgetsCollection
          .where('userId', isEqualTo: userId)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return BudgetModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }
  
  // Get all budgets for a user
  Future<List<BudgetModel>> getUserBudgets(String userId) async {
    return _handleFirestoreOperation(() async {
      QuerySnapshot snapshot = await _budgetsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('startDate', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc))
          .toList();
    });
  }
  
  // Delete budget
  Future<void> deleteBudget(String budgetId) async {
    return _handleFirestoreOperation(() async {
      await _budgetsCollection.doc(budgetId).delete();
    });
  }
  
  // INCOMES COLLECTION OPERATIONS
  
  // Add income
  Future<String> addIncome(IncomeModel income) async {
    return _handleFirestoreOperation(() async {
      DocumentReference docRef = await _incomesCollection.add(income.toFirestore());
      return docRef.id;
    });
  }
  
  // Update income
  Future<void> updateIncome(IncomeModel income) async {
    return _handleFirestoreOperation(() async {
      await _incomesCollection.doc(income.id).update(income.toFirestore());
    });
  }
  
  // Delete income
  Future<void> deleteIncome(String incomeId) async {
    return _handleFirestoreOperation(() async {
      await _incomesCollection.doc(incomeId).delete();
    });
  }
  
  // Get all incomes for a user
  Stream<List<IncomeModel>> getUserIncomes(String userId) {
    return _incomesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncomeModel.fromFirestore(doc))
            .toList());
  }
  
  // Get incomes by month
  Stream<List<IncomeModel>> getIncomesByMonth(String userId, int year, int month) {
    // Create DateTime objects for the start and end of the month
    DateTime startDate = DateTime(year, month, 1);
    DateTime endDate = DateTime(year, month + 1, 0, 23, 59, 59); // Last day of month
    
    return _incomesCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncomeModel.fromFirestore(doc))
            .toList());
  }
  
  // SETTINGS COLLECTION OPERATIONS
  
  // Get user settings
  Future<SettingsModel> getUserSettings(String userId) async {
    return _handleFirestoreOperation(() async {
      DocumentSnapshot doc = await _settingsCollection.doc(userId).get();
      
      if (doc.exists) {
        return SettingsModel.fromFirestore(doc);
      }
      
      // If settings don't exist, create default settings
      SettingsModel defaultSettings = SettingsModel.defaultSettings(userId);
      await _settingsCollection.doc(userId).set(defaultSettings.toFirestore());
      return defaultSettings;
    });
  }
  
  // Update user settings
  Future<void> updateUserSettings(SettingsModel settings) async {
    return _handleFirestoreOperation(() async {
      await _settingsCollection.doc(settings.userId).set(settings.toFirestore());
    });
  }
  
  // ANALYTICS OPERATIONS
  
  // Get total income for a period
  Future<double> getTotalIncome(String userId, int year, int month) async {
    return _handleFirestoreOperation(() async {
      // Create DateTime objects for the start and end of the month
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = DateTime(year, month + 1, 0, 23, 59, 59); // Last day of month
      
      QuerySnapshot snapshot = await _incomesCollection
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      double total = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0).toDouble();
      }
      
      return total;
    });
  }
  
  // Get total expense for a period
  Future<double> getTotalExpense(String userId, int year, int month) async {
    return _handleFirestoreOperation(() async {
      // Create DateTime objects for the start and end of the month
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = DateTime(year, month + 1, 0, 23, 59, 59); // Last day of month
      
      QuerySnapshot snapshot = await _expensesCollection
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('type', isEqualTo: transaction_model.TransactionType.expense.index)
          .get();
      
      double total = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0).toDouble();
      }
      
      return total;
    });
  }
  
  // Get expense totals by category for a period
  Future<Map<String, double>> getExpenseCategoryTotals(String userId, int year, int month) async {
    return _handleFirestoreOperation(() async {
      // Create DateTime objects for the start and end of the month
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = DateTime(year, month + 1, 0, 23, 59, 59); // Last day of month
      
      QuerySnapshot snapshot = await _expensesCollection
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('type', isEqualTo: transaction_model.TransactionType.expense.index)
          .get();
      
      Map<String, double> categoryTotals = {};
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String category = data['category'] ?? 'Others';
        double amount = (data['amount'] ?? 0).toDouble();
        
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
      
      return categoryTotals;
    });
  }
  
  // Initialize default categories if none exist
  Future<void> initializeDefaultCategories() async {
    return _handleFirestoreOperation(() async {
      // Check if default categories exist
      QuerySnapshot snapshot = await _categoriesCollection
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        // Create default expense categories
        for (String category in [
          'Food',
          'Transportation',
          'Housing',
          'Entertainment',
          'Shopping',
          'Utilities',
          'Health',
          'Education',
        ]) {
          String categoryId = category.toLowerCase().replaceAll(' ', '_');
          CategoryModel categoryModel = CategoryModel(
            id: categoryId,
            name: category,
            icon: _getDefaultIconForCategory(category),
            color: _getDefaultColorForCategory(category),
            isDefault: true,
          );
          
          await _categoriesCollection.doc(categoryId).set(categoryModel.toFirestore());
        }
        
        // Create default income categories
        for (String category in [
          'Salary',
          'Freelance',
          'Investments',
          'Gifts',
        ]) {
          String categoryId = category.toLowerCase().replaceAll(' ', '_');
          CategoryModel categoryModel = CategoryModel(
            id: categoryId,
            name: category,
            icon: _getDefaultIconForCategory(category),
            color: _getDefaultColorForCategory(category),
            isDefault: true,
          );
          
          await _categoriesCollection.doc(categoryId).set(categoryModel.toFirestore());
        }
      }
    });
  }
  
  // Helper method to get default icon for category
  String _getDefaultIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return 'restaurant';
      case 'transportation':
        return 'directions_car';
      case 'housing':
        return 'home';
      case 'entertainment':
        return 'movie';
      case 'shopping':
        return 'shopping_cart';
      case 'utilities':
        return 'power';
      case 'health':
        return 'favorite';
      case 'education':
        return 'school';
      case 'salary':
        return 'work';
      case 'freelance':
        return 'laptop';
      case 'investments':
        return 'trending_up';
      case 'gifts':
        return 'card_giftcard';
      default:
        return 'category';
    }
  }
  
  // Helper method to get default color for category
  String _getDefaultColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '#4CAF50'; // Green
      case 'transportation':
        return '#2196F3'; // Blue
      case 'housing':
        return '#9C27B0'; // Purple
      case 'entertainment':
        return '#FF9800'; // Orange
      case 'shopping':
        return '#E91E63'; // Pink
      case 'utilities':
        return '#607D8B'; // Blue Grey
      case 'health':
        return '#F44336'; // Red
      case 'education':
        return '#00BCD4'; // Cyan
      case 'salary':
        return '#4CAF50'; // Green
      case 'freelance':
        return '#FFC107'; // Amber
      case 'investments':
        return '#009688'; // Teal
      case 'gifts':
        return '#9C27B0'; // Purple
      default:
        return '#757575'; // Grey
    }
  }
} 