import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction_model.dart' as model;
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/screens/analytics_screen.dart';
import 'package:expense_tracker/screens/profile_screen.dart';
import 'package:expense_tracker/utils/theme_utils.dart';
import 'package:expense_tracker/widgets/summary_card.dart';
import 'package:expense_tracker/widgets/transaction_card.dart';
import 'package:expense_tracker/widgets/transaction_form.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
              icon: const Icon(Icons.calendar_month),
              onPressed: () => _showMonthPicker(context),
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
    
    if (transactionProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        // Summary Card
        SummaryCard(
          income: transactionProvider.totalIncome,
          expenses: transactionProvider.totalExpense,
          period: transactionProvider.formattedMonth,
        ),
        
        // Month Navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => transactionProvider.changeMonth(-1),
              ),
              Text(
                transactionProvider.formattedMonth,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => transactionProvider.changeMonth(1),
              ),
            ],
          ),
        ),
        
        // Transactions List
        Expanded(
          child: transactionProvider.transactions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: transactionProvider.transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactionProvider.transactions[index];
                    return TransactionCard(
                      transaction: transaction,
                      onDelete: (id) {
                        _confirmDeleteTransaction(context, id);
                      },
                      onTap: () => _showEditTransactionForm(context, transaction),
                    );
                  },
                ),
        ),
      ],
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
        return TransactionForm(
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
        return TransactionForm(
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
  
  void _showMonthPicker(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final DateTime currentDate = transactionProvider.selectedDate;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Month'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthIndex = index + 1;
                final bool isSelected = monthIndex == currentDate.month;
                
                return InkWell(
                  onTap: () {
                    final newDate = DateTime(currentDate.year, monthIndex);
                    transactionProvider.changeMonth(monthIndex - currentDate.month);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getMonthLabel(monthIndex),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  String _getMonthLabel(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
} 