import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction_model.dart' as model;
import 'package:expense_tracker/utils/theme_utils.dart';
import 'package:intl/intl.dart';

class TransactionForm extends StatefulWidget {
  final model.Transaction? transaction;
  final Function(model.Transaction) onSave;

  const TransactionForm({
    super.key,
    this.transaction,
    required this.onSave,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  
  late model.TransactionType _type;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize with default values or existing transaction data
    _type = widget.transaction?.type ?? model.TransactionType.expense;
    _titleController = TextEditingController(text: widget.transaction?.title ?? '');
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toString() ?? '',
    );
    _noteController = TextEditingController(text: widget.transaction?.note ?? '');
    _selectedDate = widget.transaction?.date ?? DateTime.now();
    
    _updateCategories();
    
    // Set the selected category or default to first item
    _selectedCategory = widget.transaction?.category ?? _categories.first;
  }
  
  void _updateCategories() {
    _categories = _type == model.TransactionType.expense
        ? model.TransactionCategory.expenseCategories
        : model.TransactionCategory.incomeCategories;
        
    // If we're editing and the category list changed, we need to update the selection
    if (widget.transaction != null && !_categories.contains(_selectedCategory)) {
      _selectedCategory = _categories.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Form(
        key: _formKey,
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
                        _updateCategories();
                        _selectedCategory = _categories.first;
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
                        _updateCategories();
                        _selectedCategory = _categories.first;
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
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.sentences,
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
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                
                final double? amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Date Picker
            InkWell(
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd').format(_selectedDate),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Notes Field
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
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
  
  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final transaction = model.Transaction(
        id: widget.transaction?.id,
        userId: widget.transaction?.userId ?? '',
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        category: _selectedCategory,
        type: _type,
        note: _noteController.text.trim().isNotEmpty 
            ? _noteController.text.trim() 
            : null,
      );
      
      widget.onSave(transaction);
      Navigator.pop(context);
    }
  }
  
  Widget _buildTypeButton({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? color.withOpacity(0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 