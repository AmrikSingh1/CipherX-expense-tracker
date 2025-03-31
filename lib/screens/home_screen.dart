import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction_model.dart' as model;
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/providers/firestore_provider.dart';
import 'package:expense_tracker/screens/analytics_screen.dart';
import 'package:expense_tracker/screens/profile_screen.dart';
import 'package:expense_tracker/utils/theme_utils.dart';
import 'package:expense_tracker/widgets/summary_card.dart';
import 'package:expense_tracker/widgets/transaction_card.dart';
import 'package:expense_tracker/widgets/transaction_form.dart';
import 'package:expense_tracker/widgets/enhanced_transaction_form.dart';
import 'package:expense_tracker/widgets/transaction_list.dart';
import 'package:expense_tracker/widgets/date_filter_widget.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  DateTime _filterStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _filterEndDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

  @override
  void initState() {
    super.initState();
    // Initialize transactions
    Future.microtask(() {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      if (userId != null) {
        Provider.of<TransactionProvider>(context, listen: false).initTransactions(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: _selectedIndex == 0 
            ? const Text('Expense Tracker') 
            : _selectedIndex == 1 
                ? const Text('Analytics')
                : const Text('Profile'),
        centerTitle: true,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterOptions(context),
            ),
        ],
      ),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddTransactionForm(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const AnalyticsScreen();
      case 2:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final firestoreProvider = Provider.of<FirestoreProvider>(context);
    
    if (transactionProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Create a map of category IDs to names
    Map<String, String> categoryNames = {};
    if (firestoreProvider.categories != null) {
      for (final category in firestoreProvider.categories!) {
        categoryNames[category.id] = category.name;
      }
    }
    
    return Column(
      children: [
        // Summary Card
        SummaryCard(
          income: transactionProvider.totalIncome,
          expenses: transactionProvider.totalExpense,
          period: transactionProvider.formattedMonth,
        ),
        
        // Date Filter
        DateFilterWidget(
          initialStartDate: _filterStartDate,
          initialEndDate: _filterEndDate,
          onFilterChanged: (startDate, endDate) {
            setState(() {
              _filterStartDate = startDate;
              _filterEndDate = endDate;
            });
          },
        ),
        
        // Transactions List
        Expanded(
          child: transactionProvider.transactions.isEmpty
              ? _buildEmptyState()
              : TransactionList(
                  transactions: _filterTransactionsByDate(transactionProvider.transactions),
                  onDeleteTransaction: (id) => _confirmDeleteTransaction(context, id),
                  onEditTransaction: (transaction) => _showEditTransactionForm(context, transaction),
                  categoryNames: categoryNames,
                ),
        ),
      ],
    );
  }

  List<model.Transaction> _filterTransactionsByDate(List<model.Transaction> transactions) {
    return transactions.where((transaction) {
      return transaction.date.isAfter(_filterStartDate.subtract(const Duration(days: 1))) &&
             transaction.date.isBefore(_filterEndDate.add(const Duration(days: 1)));
    }).toList();
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DateFilterWidget(
                initialStartDate: _filterStartDate,
                initialEndDate: _filterEndDate,
                onFilterChanged: (startDate, endDate) {
                  setState(() {
                    _filterStartDate = startDate;
                    _filterEndDate = endDate;
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 70,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a new transaction to get started',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showAddTransactionForm(context),
            child: const Text('Add Transaction'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return EnhancedTransactionForm(
          onSave: (transaction) {
            Provider.of<TransactionProvider>(context, listen: false)
                .addTransaction(transaction);
          },
        );
      },
    );
  }

  void _showEditTransactionForm(BuildContext context, model.Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return EnhancedTransactionForm(
          transaction: transaction,
          onSave: (updatedTransaction) {
            Provider.of<TransactionProvider>(context, listen: false)
                .updateTransaction(updatedTransaction);
          },
        );
      },
    );
  }

  void _confirmDeleteTransaction(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Provider.of<TransactionProvider>(context, listen: false)
                    .deleteTransaction(id);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
} 