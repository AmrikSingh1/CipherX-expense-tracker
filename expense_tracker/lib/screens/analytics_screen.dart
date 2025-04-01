import 'package:flutter/material.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/providers/firestore_provider.dart';
import 'package:expense_tracker/utils/export_utils.dart';
import 'package:expense_tracker/widgets/expense_analytics.dart';
import 'package:expense_tracker/widgets/date_filter_widget.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final firestoreProvider = Provider.of<FirestoreProvider>(context);
    
    // Create a map of category IDs to names
    Map<String, String> categoryNames = {};
    if (firestoreProvider.categories != null) {
      for (final category in firestoreProvider.categories!) {
        categoryNames[category.id] = category.name;
      }
    }
    
    return Column(
      children: [
        // Date filter widget
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DateFilterWidget(
                initialStartDate: _startDate,
                initialEndDate: _endDate,
                onFilterChanged: (startDate, endDate) {
                  setState(() {
                    _startDate = startDate;
                    _endDate = endDate;
                  });
                },
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
        
        // Analytics widgets
        Expanded(
          child: ExpenseAnalytics(
            transactions: transactionProvider.transactions,
            startDate: _startDate,
            endDate: _endDate,
            categoryNames: categoryNames,
          ),
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    setState(() {
      // Set loading state if needed
    });
    
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      
      // Filter transactions by date
      final filteredTransactions = transactionProvider.transactions.where((transaction) {
        return transaction.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
               transaction.date.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();
      
      final result = await ExportUtils.exportTransactionsToCSV(
        filteredTransactions,
      );
      
      if (result != null) {
        if (result.startsWith('Error')) {
          _showSnackBar(result, isError: true);
        } else {
          _showSnackBar('Data exported to: $result');
        }
      }
    } catch (e) {
      _showSnackBar('Error exporting data: $e', isError: true);
    } finally {
      setState(() {
        // Clear loading state if needed
      });
    }
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
} 