import 'package:flutter/material.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/utils/export_utils.dart';
import 'package:expense_tracker/widgets/pie_chart_widget.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, double> _expenseCategoryData = {};
  Map<String, double> _incomeCategoryData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    final expenseData = await transactionProvider.getExpenseCategoryTotals();
    final incomeData = await transactionProvider.getIncomeCategoryTotals();
    
    setState(() {
      _expenseCategoryData = expenseData;
      _incomeCategoryData = incomeData;
      _isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when the selected month changes
    final transactionProvider = Provider.of<TransactionProvider>(context);
    transactionProvider.addListener(_loadData);
  }

  @override
  void dispose() {
    _tabController.dispose();
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    transactionProvider.removeListener(_loadData);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    
    return Column(
      children: [
        // Month indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  transactionProvider.changeMonth(-1);
                },
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
                onPressed: () {
                  transactionProvider.changeMonth(1);
                },
              ),
            ],
          ),
        ),
        
        // Summary section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryItem(
                    'Income',
                    transactionProvider.totalIncome,
                    Colors.green,
                    Icons.arrow_downward,
                  ),
                  const Divider(),
                  _buildSummaryItem(
                    'Expenses',
                    transactionProvider.totalExpense,
                    Colors.red,
                    Icons.arrow_upward,
                  ),
                  const Divider(),
                  _buildSummaryItem(
                    'Balance',
                    transactionProvider.balance,
                    transactionProvider.balance >= 0 ? Colors.blue : Colors.red,
                    Icons.account_balance_wallet,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Export Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: _exportData,
            icon: const Icon(Icons.file_download),
            label: const Text('Export Data'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ),
        
        // Chart tabs
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
        
        // Chart content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Expenses Chart
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CategoryPieChart(
                            categoryData: _expenseCategoryData,
                            isExpense: true,
                          ),
                        ],
                      ),
                    ),
              
              // Income Chart
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CategoryPieChart(
                            categoryData: _incomeCategoryData,
                            isExpense: false,
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final result = await ExportUtils.exportTransactionsToCSV(
        transactionProvider.transactions,
      );
      
      if (result != null) {
        if (result.startsWith('Error')) {
          _showSnackBar(result, isError: true);
        } else {
          _showSnackBar('Data exported to: $result');
        }
      }
    } catch (e) {
      _showSnackBar('Export failed: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: const Duration(seconds: 3),
      ),
    );
  }
} 