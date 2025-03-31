import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction_model.dart' as model;
import 'package:expense_tracker/utils/theme_utils.dart';
import 'package:expense_tracker/widgets/transaction_card.dart';
import 'package:intl/intl.dart';

enum SortOption {
  dateDesc('Date (Newest First)'),
  dateAsc('Date (Oldest First)'),
  amountDesc('Amount (Highest First)'),
  amountAsc('Amount (Lowest First)'),
  titleAsc('Title (A-Z)'),
  titleDesc('Title (Z-A)'),
  categoryAsc('Category (A-Z)'),
  categoryDesc('Category (Z-A)');
  
  final String displayName;
  const SortOption(this.displayName);
}

class TransactionList extends StatefulWidget {
  final List<model.Transaction> transactions;
  final Function(String) onDeleteTransaction;
  final Function(model.Transaction) onEditTransaction;
  final bool showFilters;
  final bool showSorting;
  final Map<String, String> categoryNames; // Map from category ID to name
  
  const TransactionList({
    super.key,
    required this.transactions,
    required this.onDeleteTransaction,
    required this.onEditTransaction,
    this.showFilters = true,
    this.showSorting = true,
    this.categoryNames = const {},
  });

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  SortOption _sortOption = SortOption.dateDesc;
  String? _selectedType;
  String? _selectedCategory;
  List<model.Transaction> _filteredTransactions = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _applyFiltersAndSort();
  }
  
  @override
  void didUpdateWidget(TransactionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions != oldWidget.transactions) {
      _applyFiltersAndSort();
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _applyFiltersAndSort() {
    // Apply any filters
    _filteredTransactions = widget.transactions.where((transaction) {
      // Filter by type
      if (_selectedType != null) {
        if (_selectedType == 'income' && 
            transaction.type != model.TransactionType.income) {
          return false;
        } else if (_selectedType == 'expense' && 
            transaction.type != model.TransactionType.expense) {
          return false;
        }
      }
      
      // Filter by category
      if (_selectedCategory != null && transaction.category != _selectedCategory) {
        return false;
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = transaction.title.toLowerCase();
        final note = transaction.note?.toLowerCase() ?? '';
        final category = (widget.categoryNames[transaction.category] ?? transaction.category).toLowerCase();
        
        return title.contains(query) || 
               note.contains(query) || 
               category.contains(query);
      }
      
      return true;
    }).toList();
    
    // Apply sorting
    _filteredTransactions.sort((a, b) {
      switch (_sortOption) {
        case SortOption.dateDesc:
          return b.date.compareTo(a.date);
        case SortOption.dateAsc:
          return a.date.compareTo(b.date);
        case SortOption.amountDesc:
          return b.amount.compareTo(a.amount);
        case SortOption.amountAsc:
          return a.amount.compareTo(b.amount);
        case SortOption.titleAsc:
          return a.title.compareTo(b.title);
        case SortOption.titleDesc:
          return b.title.compareTo(a.title);
        case SortOption.categoryAsc:
          final categoryA = widget.categoryNames[a.category] ?? a.category;
          final categoryB = widget.categoryNames[b.category] ?? b.category;
          return categoryA.compareTo(categoryB);
        case SortOption.categoryDesc:
          final categoryA = widget.categoryNames[a.category] ?? a.category;
          final categoryB = widget.categoryNames[b.category] ?? b.category;
          return categoryB.compareTo(categoryA);
      }
    });
    
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    // Get unique categories for filtering
    final Set<String> categories = widget.transactions
        .map((t) => t.category)
        .toSet();
    
    return Column(
      children: [
        if (widget.showFilters) _buildFilterBar(categories),
        
        if (_filteredTransactions.isEmpty)
          _buildEmptyState()
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _filteredTransactions.length,
              itemBuilder: (context, index) {
                final transaction = _filteredTransactions[index];
                final prevTransaction = index > 0 ? _filteredTransactions[index - 1] : null;
                
                // Check if this is the first transaction of the day
                final bool isFirstOfDay = prevTransaction == null || 
                    !DateUtils.isSameDay(transaction.date, prevTransaction.date);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirstOfDay)
                      _buildDateHeader(transaction.date),
                      
                    TransactionCard(
                      transaction: transaction,
                      onDelete: widget.onDeleteTransaction,
                      onTap: () => widget.onEditTransaction(transaction),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
  
  Widget _buildFilterBar(Set<String> categories) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _applyFiltersAndSort();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFiltersAndSort();
              });
            },
          ),
        ),
        
        // Filter chips row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Type filters
              FilterChip(
                label: const Text('All'),
                selected: _selectedType == null,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = null;
                    _applyFiltersAndSort();
                  });
                },
                backgroundColor: Colors.grey[200],
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Income'),
                selected: _selectedType == 'income',
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? 'income' : null;
                    _applyFiltersAndSort();
                  });
                },
                backgroundColor: Colors.grey[200],
                selectedColor: AppTheme.incomeColor.withOpacity(0.2),
                checkmarkColor: AppTheme.incomeColor,
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Expense'),
                selected: _selectedType == 'expense',
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? 'expense' : null;
                    _applyFiltersAndSort();
                  });
                },
                backgroundColor: Colors.grey[200],
                selectedColor: AppTheme.expenseColor.withOpacity(0.2),
                checkmarkColor: AppTheme.expenseColor,
              ),
              
              if (categories.isNotEmpty) const SizedBox(width: 16),
              
              // Category filters
              if (categories.isNotEmpty)
                ...categories.map((category) {
                  final displayName = widget.categoryNames[category] ?? category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(displayName),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                          _applyFiltersAndSort();
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryColor,
                    ),
                  );
                }),
            ],
          ),
        ),
        
        // Sorting options
        if (widget.showSorting)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Text('Sort by:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<SortOption>(
                    value: _sortOption,
                    isExpanded: true,
                    underline: Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    onChanged: (SortOption? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _sortOption = newValue;
                          _applyFiltersAndSort();
                        });
                      }
                    },
                    items: SortOption.values.map((option) {
                      return DropdownMenuItem<SortOption>(
                        value: option,
                        child: Text(option.displayName),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        
        const Divider(),
      ],
    );
  }
  
  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    String dateText;
    
    if (DateUtils.isSameDay(date, now)) {
      dateText = 'Today';
    } else if (DateUtils.isSameDay(date, yesterday)) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('EEEE, MMMM d, yyyy').format(date);
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != null || _selectedType != null
                  ? 'No transactions match your filters'
                  : 'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isNotEmpty || _selectedCategory != null || _selectedType != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedCategory = null;
                    _selectedType = null;
                    _applyFiltersAndSort();
                  });
                },
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Clear all filters'),
              ),
          ],
        ),
      ),
    );
  }
} 