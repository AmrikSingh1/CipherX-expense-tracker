import 'package:flutter/material.dart';
import 'package:expense_tracker/utils/format_utils.dart';
import 'package:expense_tracker/utils/theme_utils.dart';

class SummaryCard extends StatelessWidget {
  final double income;
  final double expenses;
  final String period;

  const SummaryCard({
    super.key,
    required this.income,
    required this.expenses,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final double balance = income - expenses;
    final bool isPositive = balance >= 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                Color(0xFF7E57C2),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period (Month/Year)
              Text(
                period,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              
              // Balance
              Text(
                'Balance',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              Text(
                FormatUtils.formatCurrency(balance),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.white : Colors.red.shade200,
                ),
              ),
              const SizedBox(height: 24),
              
              // Income and Expenses
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Income
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.arrow_downward,
                            color: AppTheme.incomeColor,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Income',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FormatUtils.formatCurrency(income),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  // Expenses
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.arrow_upward,
                            color: AppTheme.expenseColor,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Expenses',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FormatUtils.formatCurrency(expenses),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 