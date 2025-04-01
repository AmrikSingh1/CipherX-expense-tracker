import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction_model.dart' as model;
import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/firestore_provider.dart';
import 'package:expense_tracker/utils/theme_utils.dart';
import 'package:expense_tracker/widgets/category_selector.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/widgets/create_category_dialog.dart';
import 'package:expense_tracker/models/recurring_model.dart';
import 'package:expense_tracker/widgets/recurring_transaction_dialog.dart';

class EnhancedTransactionForm extends StatefulWidget {
  final model.Transaction? transaction;
  final Function(model.Transaction) onSave;

  const EnhancedTransactionForm({
    super.key,
    this.transaction,
    required this.onSave,
  });

  @override
  State<EnhancedTransactionForm> createState() => _EnhancedTransactionFormState();
}

class _EnhancedTransactionFormState extends State<EnhancedTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();
  
  late model.TransactionType _type;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  String? _selectedPaymentMethod;
  bool _isRecurring = false;
  
  final List<String> _paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'Mobile Payment',
    'Check',
    'Other',
  ];
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _formChanged = false;
  
  // Add these fields for recurring transaction
  RecurrenceFrequency _recurrenceFrequency = RecurrenceFrequency.monthly;
  DateTime? _recurrenceEndDate;
  bool _showRecurrenceConfig = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize with default values or existing transaction data
    _type = widget.transaction?.type ?? model.TransactionType.expense;
    _titleController = TextEditingController(text: widget.transaction?.title ?? '');
    _amountController = TextEditingController(
      text: widget.transaction?.amount != null && widget.transaction!.amount > 0 
          ? widget.transaction!.amount.toString() 
          : '',
    );
    _noteController = TextEditingController(text: widget.transaction?.note ?? '');
    _selectedDate = widget.transaction?.date ?? DateTime.now();
    _selectedCategoryId = widget.transaction?.category;
    _selectedPaymentMethod = widget.transaction?.paymentMethod ?? _paymentMethods.first;
    _isRecurring = widget.transaction?.isRecurring ?? false;
    
    // Listen for changes to mark form as dirty
    _titleController.addListener(_markFormChanged);
    _amountController.addListener(_markFormChanged);
    _noteController.addListener(_markFormChanged);
  }
  
  void _markFormChanged() {
    if (!_formChanged) {
      setState(() {
        _formChanged = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _titleFocusNode.dispose();
    _amountFocusNode.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreProvider = Provider.of<FirestoreProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';
    
    // Filter categories based on transaction type
    List<CategoryModel> filteredCategories = [];
    if (firestoreProvider.categories != null) {
      filteredCategories = firestoreProvider.categories!
          .where((category) {
            // In a real app, you'd have a type field in CategoryModel 
            // For now, we'll just filter by default categories vs user-created ones
            if (_type == model.TransactionType.expense) {
              return category.isDefault || category.createdBy == userId;
            } else {
              return !category.isDefault || category.createdBy == userId;
            }
          })
          .toList();
    }
    
    // Set a default category if none is selected
    if (_selectedCategoryId == null && filteredCategories.isNotEmpty) {
      _selectedCategoryId = filteredCategories.first.id;
    }
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Form(
        key: _formKey,
        onWillPop: _onWillPop,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Title
            Text(
              widget.transaction == null
                  ? 'Add Transaction'
                  : 'Edit Transaction',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            
            // Transaction Type Selector
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    title: 'Expense',
                    icon: Icons.arrow_upward,
                    color: AppTheme.expenseColor,
                    isSelected: _type == model.TransactionType.expense,
                    onTap: () {
                      setState(() {
                        _type = model.TransactionType.expense;
                        _selectedCategoryId = null; // Reset category when changing type
                        _formChanged = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTypeButton(
                    title: 'Income',
                    icon: Icons.arrow_downward,
                    color: AppTheme.incomeColor,
                    isSelected: _type == model.TransactionType.income,
                    onTap: () {
                      setState(() {
                        _type = model.TransactionType.income;
                        _selectedCategoryId = null; // Reset category when changing type
                        _formChanged = true;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Title Field
            TextFormField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              decoration: InputDecoration(
                labelText: 'Title',
                prefixIcon: const Icon(Icons.title),
                hintText: _type == model.TransactionType.expense 
                    ? 'e.g., Lunch at Restaurant' 
                    : 'e.g., Salary Payment',
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_amountFocusNode);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Amount Field
            TextFormField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: const Icon(Icons.attach_money),
                hintText: '0.00',
                helperText: _type == model.TransactionType.expense 
                    ? 'How much did you spend?' 
                    : 'How much did you receive?',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_noteFocusNode);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                
                final double? amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter a valid number';
                }
                
                if (amount <= 0) {
                  return 'Amount must be greater than zero';
                }
                
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Category Selector
            if (filteredCategories.isNotEmpty)
              CategorySelector(
                categories: filteredCategories,
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: (categoryId) {
                  setState(() {
                    _selectedCategoryId = categoryId;
                    _formChanged = true;
                  });
                },
                onAddCategory: () {
                  // Show the create category dialog
                  showDialog(
                    context: context,
                    builder: (context) => CreateCategoryDialog(
                      userId: Provider.of<AuthProvider>(context, listen: false).user!.uid,
                      isExpense: _type == model.TransactionType.expense,
                      onSave: (newCategory) {
                        // Save the category to Firestore via the provider
                        Provider.of<FirestoreProvider>(context, listen: false)
                            .saveCategory(newCategory);
                        
                        // Select the new category
                        setState(() {
                          _selectedCategoryId = newCategory.id;
                          _formChanged = true;
                        });
                        
                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Category "${newCategory.name}" created successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            
            // Date Picker
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Payment Method Dropdown
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: Icon(Icons.payment),
              ),
              items: _paymentMethods.map((method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value;
                  _formChanged = true;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Recurring Switch
            SwitchListTile(
              title: const Text('Recurring Transaction'),
              subtitle: _isRecurring
                  ? Text(_getRecurrenceDescription())
                  : const Text('Will this transaction repeat in the future?'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                  _formChanged = true;

                  if (value && !_showRecurrenceConfig) {
                    _showRecurrenceConfig = true;
                    // Show recurring settings dialog when enabled
                    _showRecurringSettingsDialog();
                  }
                });
              },
              secondary: const Icon(Icons.repeat),
            ),
            
            // Show Configure button if recurring is enabled
            if (_isRecurring)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: TextButton.icon(
                  onPressed: _showRecurringSettingsDialog,
                  icon: const Icon(Icons.settings),
                  label: const Text('Configure Recurring Settings'),
                ),
              ),
            
            // Notes Field
            TextFormField(
              controller: _noteController,
              focusNode: _noteFocusNode,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: Icon(Icons.note),
                hintText: 'Add any additional details...',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            
            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.transaction == null ? 'Add Transaction' : 'Update Transaction',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<bool> _onWillPop() async {
    if (!_formChanged) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DISCARD'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _type == model.TransactionType.expense 
                  ? AppTheme.expenseColor 
                  : AppTheme.incomeColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _formChanged = true;
      });
    }
  }
  
  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategoryId == null) {
      setState(() {
        _errorMessage = 'Please select a category';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? '';
      
      if (userId.isEmpty) {
        setState(() {
          _errorMessage = 'You must be logged in to add transactions';
          _isLoading = false;
        });
        return;
      }
      
      final double amount = double.parse(_amountController.text);
      
      if (_isRecurring) {
        // Create recurring transaction
        final RecurringTransaction recurringTransaction = RecurringTransaction(
          userId: userId,
          title: _titleController.text.trim(),
          amount: amount,
          category: _selectedCategoryId!,
          type: _type,
          frequency: _recurrenceFrequency,
          startDate: _selectedDate,
          endDate: _recurrenceEndDate,
          note: _noteController.text.trim(),
          paymentMethod: _selectedPaymentMethod,
        );
        
        // Save recurring transaction
        await Provider.of<FirestoreProvider>(context, listen: false)
            .saveRecurringTransaction(recurringTransaction);
            
        // Also create the first occurrence as a regular transaction
        final model.Transaction firstOccurrence = model.Transaction(
          userId: userId,
          title: _titleController.text.trim(),
          amount: amount,
          date: _selectedDate,
          category: _selectedCategoryId!,
          type: _type,
          note: _noteController.text.trim(),
          paymentMethod: _selectedPaymentMethod,
          isRecurring: true,
        );
        
        widget.onSave(firstOccurrence);
      } else {
        // Create regular transaction
        final model.Transaction transaction = model.Transaction(
          id: widget.transaction?.id ?? const Uuid().v4(),
          userId: userId,
          title: _titleController.text.trim(),
          amount: amount,
          date: _selectedDate,
          category: _selectedCategoryId!,
          type: _type,
          note: _noteController.text.trim(),
          paymentMethod: _selectedPaymentMethod,
          isRecurring: _isRecurring,
          attachmentUrl: widget.transaction?.attachmentUrl,
          createdAt: widget.transaction?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        widget.onSave(transaction);
      }
      
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving transaction: $e';
        _isLoading = false;
      });
    }
  }
  
  Widget _buildTypeButton({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Add this method to handle recurring transaction settings
  void _showRecurringSettingsDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => RecurringTransactionDialog(
        initialFrequency: _recurrenceFrequency,
        initialStartDate: _selectedDate,
        initialEndDate: _recurrenceEndDate,
      ),
    );
    
    if (result != null) {
      setState(() {
        _recurrenceFrequency = result['frequency'] as RecurrenceFrequency;
        _selectedDate = result['startDate'] as DateTime; // Update start date
        _recurrenceEndDate = result['endDate'] as DateTime?;
        _formChanged = true;
      });
    }
  }
  
  // Add this method to show a summary of the recurrence settings
  String _getRecurrenceDescription() {
    String frequencyText;
    switch (_recurrenceFrequency) {
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
    
    return '$frequencyText${_recurrenceEndDate != null ? ' until ${DateFormat('MM/dd/yyyy').format(_recurrenceEndDate!)}' : ''}';
  }
} 