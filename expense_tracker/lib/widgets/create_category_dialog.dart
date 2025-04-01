import 'package:flutter/material.dart';
import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/utils/theme_utils.dart';

class CreateCategoryDialog extends StatefulWidget {
  final Function(CategoryModel) onSave;
  final String userId;
  final bool isExpense; // To determine whether it's an expense or income category

  const CreateCategoryDialog({
    super.key,
    required this.onSave,
    required this.userId,
    this.isExpense = true,
  });

  @override
  State<CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<CreateCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _selectedIcon = 'category';
  Color _selectedColor = AppTheme.primaryColor;
  bool _isLoading = false;
  
  // Icon choices for categories
  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'Food', 'icon': Icons.fastfood, 'value': 'restaurant'},
    {'name': 'Transport', 'icon': Icons.directions_car, 'value': 'directions_car'},
    {'name': 'Shopping', 'icon': Icons.shopping_cart, 'value': 'shopping_cart'},
    {'name': 'Bills', 'icon': Icons.receipt, 'value': 'receipt'},
    {'name': 'Entertainment', 'icon': Icons.movie, 'value': 'movie'},
    {'name': 'Health', 'icon': Icons.favorite, 'value': 'favorite'},
    {'name': 'Education', 'icon': Icons.school, 'value': 'school'},
    {'name': 'Home', 'icon': Icons.home, 'value': 'home'},
    {'name': 'Work', 'icon': Icons.work, 'value': 'work'},
    {'name': 'Gift', 'icon': Icons.card_giftcard, 'value': 'card_giftcard'},
    {'name': 'Savings', 'icon': Icons.savings, 'value': 'savings'},
    {'name': 'Investment', 'icon': Icons.trending_up, 'value': 'trending_up'},
    {'name': 'Other', 'icon': Icons.category, 'value': 'category'},
  ];
  
  // Color choices for categories
  final List<Color> _colorOptions = [
    AppTheme.primaryColor,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create New ${widget.isExpense ? 'Expense' : 'Income'} Category'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'Enter category name',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Icon Selection
              const Text('Choose an Icon:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _iconOptions.length,
                  itemBuilder: (context, index) {
                    final option = _iconOptions[index];
                    final bool isSelected = _selectedIcon == option['value'];
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIcon = option['value'];
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? _selectedColor.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? _selectedColor : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          option['icon'],
                          color: isSelected ? _selectedColor : Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Color Selection
              const Text('Choose a Color:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _colorOptions.length,
                  itemBuilder: (context, index) {
                    final color = _colorOptions[index];
                    final bool isSelected = _selectedColor == color;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCategory,
          child: _isLoading
              ? const SizedBox(
                  height: 20, 
                  width: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('SAVE'),
        ),
      ],
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Generate a slug-like ID from the category name
      final String categoryId = _nameController.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '_');
      
      // Convert color to hex string
      final String colorHex = '#${_selectedColor.value.toRadixString(16).substring(2)}';
      
      final CategoryModel newCategory = CategoryModel(
        id: '${categoryId}_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: colorHex,
        isDefault: false,
        createdBy: widget.userId,
      );
      
      widget.onSave(newCategory);
      
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      // Show error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating category: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
} 