import 'package:flutter/material.dart';
import 'package:expense_tracker/utils/theme_utils.dart';
import 'package:intl/intl.dart';

enum DateFilterType {
  day,
  week,
  month,
  quarter,
  year,
  custom,
}

class DateFilterWidget extends StatefulWidget {
  final DateFilterType initialFilter;
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final Function(DateTime startDate, DateTime endDate) onFilterChanged;

  const DateFilterWidget({
    super.key,
    this.initialFilter = DateFilterType.month,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onFilterChanged,
  });

  @override
  State<DateFilterWidget> createState() => _DateFilterWidgetState();
}

class _DateFilterWidgetState extends State<DateFilterWidget> {
  late DateFilterType _selectedFilter;
  late DateTime _startDate;
  late DateTime _endDate;
  
  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }
  
  void _applyFilter(DateFilterType filterType) {
    final now = DateTime.now();
    DateTime start = _startDate;
    DateTime end = _endDate;
    
    switch (filterType) {
      case DateFilterType.day:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DateFilterType.week:
        // Find the first day of the week (Monday)
        final dayOfWeek = now.weekday;
        start = DateTime(now.year, now.month, now.day - dayOfWeek + 1);
        end = DateTime(now.year, now.month, now.day + (7 - dayOfWeek), 23, 59, 59);
        break;
      case DateFilterType.month:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case DateFilterType.quarter:
        final quarter = (now.month - 1) ~/ 3;
        start = DateTime(now.year, quarter * 3 + 1, 1);
        end = DateTime(now.year, (quarter + 1) * 3 + 1, 0, 23, 59, 59);
        break;
      case DateFilterType.year:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case DateFilterType.custom:
        // Keep existing dates for custom filter
        break;
    }
    
    setState(() {
      _selectedFilter = filterType;
      _startDate = start;
      _endDate = end;
    });
    
    widget.onFilterChanged(start, end);
  }
  
  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedFilter = DateFilterType.custom;
        _startDate = picked.start;
        _endDate = DateTime(
          picked.end.year, 
          picked.end.month, 
          picked.end.day, 
          23, 59, 59
        );
      });
      
      widget.onFilterChanged(_startDate, _endDate);
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
                'Filter by',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton.icon(
                onPressed: _selectCustomDateRange,
                icon: const Icon(Icons.date_range),
                label: const Text('Custom'),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _buildFilterChip(DateFilterType.day, 'Today'),
              _buildFilterChip(DateFilterType.week, 'This Week'),
              _buildFilterChip(DateFilterType.month, 'This Month'),
              _buildFilterChip(DateFilterType.quarter, 'This Quarter'),
              _buildFilterChip(DateFilterType.year, 'This Year'),
              if (_selectedFilter == DateFilterType.custom)
                Chip(
                  label: Text(
                    '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate)}',
                    style: TextStyle(
                      color: _selectedFilter == DateFilterType.custom ? Colors.white : Colors.black,
                    ),
                  ),
                  backgroundColor: _selectedFilter == DateFilterType.custom 
                      ? AppTheme.primaryColor 
                      : Colors.grey[200],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Showing transactions from ${DateFormat('MMM d, yyyy').format(_startDate)} to ${DateFormat('MMM d, yyyy').format(_endDate)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterChip(DateFilterType type, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: _selectedFilter == type ? Colors.white : Colors.black,
          ),
        ),
        selected: _selectedFilter == type,
        onSelected: (selected) {
          if (selected) {
            _applyFilter(type);
          }
        },
        backgroundColor: Colors.grey[200],
        selectedColor: AppTheme.primaryColor,
      ),
    );
  }
} 