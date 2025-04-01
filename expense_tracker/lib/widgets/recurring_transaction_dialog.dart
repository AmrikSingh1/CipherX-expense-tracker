import 'package:flutter/material.dart';
import 'package:expense_tracker/models/recurring_model.dart';
import 'package:expense_tracker/utils/theme_utils.dart';
import 'package:intl/intl.dart';

class RecurringTransactionDialog extends StatefulWidget {
  final RecurrenceFrequency initialFrequency;
  final DateTime initialStartDate;
  final DateTime? initialEndDate;

  const RecurringTransactionDialog({
    super.key,
    this.initialFrequency = RecurrenceFrequency.monthly,
    required this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<RecurringTransactionDialog> createState() => _RecurringTransactionDialogState();
}

class _RecurringTransactionDialogState extends State<RecurringTransactionDialog> {
  late RecurrenceFrequency _frequency;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _hasEndDate = false;
  
  @override
  void initState() {
    super.initState();
    _frequency = widget.initialFrequency;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _hasEndDate = widget.initialEndDate != null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recurring Transaction Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Frequency selection
            const Text('Frequency'),
            const SizedBox(height: 8),
            DropdownButtonFormField<RecurrenceFrequency>(
              value: _frequency,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: [
                DropdownMenuItem(
                  value: RecurrenceFrequency.daily,
                  child: _buildFrequencyOption(Icons.calendar_today, 'Daily'),
                ),
                DropdownMenuItem(
                  value: RecurrenceFrequency.weekly,
                  child: _buildFrequencyOption(Icons.calendar_view_week, 'Weekly'),
                ),
                DropdownMenuItem(
                  value: RecurrenceFrequency.monthly,
                  child: _buildFrequencyOption(Icons.calendar_view_month, 'Monthly'),
                ),
                DropdownMenuItem(
                  value: RecurrenceFrequency.quarterly,
                  child: _buildFrequencyOption(Icons.calendar_view_month, 'Quarterly'),
                ),
                DropdownMenuItem(
                  value: RecurrenceFrequency.yearly,
                  child: _buildFrequencyOption(Icons.calendar_today, 'Yearly'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _frequency = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Start date
            const Text('Start Date'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectStartDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM d, yyyy').format(_startDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_month, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // End date toggle
            CheckboxListTile(
              title: const Text('Set End Date'),
              value: _hasEndDate,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() {
                  _hasEndDate = value ?? false;
                  if (_hasEndDate && _endDate == null) {
                    // Default end date 1 year from start date
                    _endDate = DateTime(
                      _startDate.year + 1,
                      _startDate.month,
                      _startDate.day,
                    );
                  }
                });
              },
            ),
            
            // End date picker (if enabled)
            if (_hasEndDate) ...[
              const SizedBox(height: 8),
              const Text('End Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectEndDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _endDate != null
                            ? DateFormat('MMM d, yyyy').format(_endDate!)
                            : 'Select End Date',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_month, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
            
            // Summary text based on selection
            const SizedBox(height: 24),
            Text(
              _buildSummaryText(),
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              {
                'frequency': _frequency,
                'startDate': _startDate,
                'endDate': _hasEndDate ? _endDate : null,
              },
            );
          },
          child: const Text('SAVE'),
        ),
      ],
    );
  }
  
  Widget _buildFrequencyOption(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
  
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, update it
        if (_hasEndDate && _endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = DateTime(
            _startDate.year + 1,
            _startDate.month,
            _startDate.day,
          );
        }
      });
    }
  }
  
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime(_startDate.year + 1, _startDate.month, _startDate.day),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }
  
  String _buildSummaryText() {
    String frequencyText;
    switch (_frequency) {
      case RecurrenceFrequency.daily:
        frequencyText = 'every day';
        break;
      case RecurrenceFrequency.weekly:
        frequencyText = 'every week';
        break;
      case RecurrenceFrequency.monthly:
        frequencyText = 'every month';
        break;
      case RecurrenceFrequency.quarterly:
        frequencyText = 'every 3 months';
        break;
      case RecurrenceFrequency.yearly:
        frequencyText = 'every year';
        break;
    }
    
    String startDateText = DateFormat('MMM d, yyyy').format(_startDate);
    String endDateText = _hasEndDate && _endDate != null
        ? ' until ${DateFormat('MMM d, yyyy').format(_endDate!)}'
        : ' with no end date';
    
    return 'This transaction will repeat $frequencyText starting on $startDateText$endDateText.';
  }
} 