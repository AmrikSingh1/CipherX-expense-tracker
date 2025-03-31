import 'package:flutter/material.dart';
import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/utils/theme_utils.dart';

class CategorySelector extends StatefulWidget {
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final Function(String categoryId) onCategorySelected;
  final VoidCallback? onAddCategory;

  const CategorySelector({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.onAddCategory,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
  }

  @override
  void didUpdateWidget(CategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategoryId != oldWidget.selectedCategoryId) {
      _selectedCategoryId = widget.selectedCategoryId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (widget.onAddCategory != null)
                TextButton.icon(
                  onPressed: widget.onAddCategory,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              ...widget.categories.map((category) => _buildCategoryItem(category)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(CategoryModel category) {
    final bool isSelected = _selectedCategoryId == category.id;
    // Parse the color string to a Color object
    Color categoryColor = AppTheme.primaryColor;
    try {
      if (category.color.startsWith('#')) {
        categoryColor = Color(int.parse(category.color.substring(1, 7), radix: 16) + 0xFF000000);
      }
    } catch (e) {
      // Use default color if parsing fails
    }
    
    // Parse the icon string to an IconData
    IconData iconData = Icons.category;
    try {
      // This is simplistic - in a real app you'd need a proper mapping of strings to IconData
      switch (category.icon) {
        case 'food':
          iconData = Icons.fastfood;
          break;
        case 'transport':
          iconData = Icons.directions_car;
          break;
        case 'entertainment':
          iconData = Icons.movie;
          break;
        case 'shopping':
          iconData = Icons.shopping_bag;
          break;
        case 'health':
          iconData = Icons.medical_services;
          break;
        case 'education':
          iconData = Icons.school;
          break;
        case 'bills':
          iconData = Icons.receipt;
          break;
        case 'salary':
          iconData = Icons.work;
          break;
        case 'gift':
          iconData = Icons.card_giftcard;
          break;
        case 'investment':
          iconData = Icons.trending_up;
          break;
        default:
          iconData = Icons.category;
      }
    } catch (e) {
      // Use default icon if parsing fails
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategoryId = category.id;
          });
          widget.onCategorySelected(category.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? categoryColor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? categoryColor : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                iconData,
                color: isSelected ? categoryColor : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                category.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? categoryColor : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 