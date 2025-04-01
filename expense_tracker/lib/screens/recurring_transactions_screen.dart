import 'package:flutter/material.dart';
import 'package:expense_tracker/models/recurring_model.dart';
import 'package:expense_tracker/models/transaction_model.dart' as model;
import 'package:expense_tracker/providers/firestore_provider.dart';
import 'package:expense_tracker/utils/format_utils.dart';
import 'package:expense_tracker/utils/theme_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RecurringTransactionsScreen extends StatelessWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final firestoreProvider = Provider.of<FirestoreProvider>(context);
    final List<RecurringTransaction>? recurringTransactions = firestoreProvider.recurringTransactions;
    
    if (firestoreProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (firestoreProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${firestoreProvider.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => firestoreProvider.clearError(),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }
    
    if (recurringTransactions == null || recurringTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.repeat,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No recurring transactions',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a transaction and enable the recurring option',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Group transactions by active/inactive status
    final List<RecurringTransaction> activeTransactions = recurringTransactions
        .where((transaction) => transaction.isActive)
        .toList();
        
    final List<RecurringTransaction> inactiveTransactions = recurringTransactions
        .where((transaction) => !transaction.isActive)
        .toList();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeTransactions.isNotEmpty) ...[
          const Text(
            'Active',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...activeTransactions.map((transaction) => _buildTransactionCard(context, transaction)),
        ],
        
        if (inactiveTransactions.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Inactive',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...inactiveTransactions.map((transaction) => _buildTransactionCard(context, transaction)),
        ],
      ],
    );
  }
  
  Widget _buildTransactionCard(BuildContext context, RecurringTransaction transaction) {
    final bool isIncome = transaction.type == model.TransactionType.income;
    final Color color = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
    
    // Format frequency text
    String frequencyText;
    switch (transaction.frequency) {
      case RecurrenceFrequency.daily:
        frequencyText = 'Daily';
        break;
      case RecurrenceFrequency.weekly:
        frequencyText = 'Weekly';
        break;
      case RecurrenceFrequency.monthly:
        frequencyText = 'Monthly';
        break;
      case RecurrenceFrequency.quarterly:
        frequencyText = 'Quarterly';
        break;
      case RecurrenceFrequency.yearly:
        frequencyText = 'Yearly';
        break;
    }
    
    // Calculate next due date
    String nextDueText = 'Next: ';
    if (transaction.lastProcessed == null) {
      nextDueText += DateFormat('MMM d, yyyy').format(transaction.startDate);
    } else {
      final DateTime nextDue = transaction.getNextDueDate();
      nextDueText += DateFormat('MMM d, yyyy').format(nextDue);
    }
    
    // Format end date if any
    String endDateText = '';
    if (transaction.endDate != null) {
      endDateText = ' until ${DateFormat('MMM d, yyyy').format(transaction.endDate!)}';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transaction.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'} ${FormatUtils.formatCurrency(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction.category,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                Switch(
                  value: transaction.isActive,
                  onChanged: (value) => _toggleActiveStatus(context, transaction, value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(frequencyText),
                  backgroundColor: color.withOpacity(0.1),
                  side: BorderSide(color: color.withOpacity(0.3)),
                  labelStyle: TextStyle(color: color),
                ),
                Chip(
                  label: Text(nextDueText),
                  backgroundColor: Colors.grey[200],
                ),
                if (transaction.endDate != null)
                  Chip(
                    label: Text('Ends: ${DateFormat('MM/dd/yyyy').format(transaction.endDate!)}'),
                    backgroundColor: Colors.grey[200],
                  ),
              ],
            ),
            if (transaction.note != null && transaction.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                transaction.note!,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            ButtonBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editRecurringTransaction(context, transaction),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, transaction),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _toggleActiveStatus(BuildContext context, RecurringTransaction transaction, bool isActive) {
    final firestoreProvider = Provider.of<FirestoreProvider>(context, listen: false);
    
    final updatedTransaction = transaction.copyWith(
      isActive: isActive,
      updatedAt: DateTime.now(),
    );
    
    firestoreProvider.updateRecurringTransaction(updatedTransaction);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${transaction.title} ${isActive ? 'activated' : 'deactivated'}'),
        backgroundColor: isActive ? Colors.green : Colors.orange,
      ),
    );
  }
  
  void _editRecurringTransaction(BuildContext context, RecurringTransaction transaction) {
    // We'll implement this in a future update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality will be available in a future update'),
      ),
    );
  }
  
  void _confirmDelete(BuildContext context, RecurringTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Transaction'),
        content: Text(
          'Are you sure you want to delete "${transaction.title}"? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecurringTransaction(context, transaction);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
  
  void _deleteRecurringTransaction(BuildContext context, RecurringTransaction transaction) {
    final firestoreProvider = Provider.of<FirestoreProvider>(context, listen: false);
    firestoreProvider.deleteRecurringTransaction(transaction.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${transaction.title} deleted'),
        backgroundColor: Colors.red,
      ),
    );
  }
} 