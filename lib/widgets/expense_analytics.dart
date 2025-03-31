import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction_model.dart' as model;
import 'package:expense_tracker/utils/theme_utils.dart';
import 'package:expense_tracker/widgets/pie_chart_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ExpenseAnalytics extends StatefulWidget {
  final List<model.Transaction> transactions;
  final Map<String, String> categoryNames; // Map from category ID to name
  final DateTime startDate;
  final DateTime endDate;

  const ExpenseAnalytics({
    super.key,
    required this.transactions,
    required this.startDate,
    required this.endDate,
    this.categoryNames = const {},
  });

  @override
  State<ExpenseAnalytics> createState() => _ExpenseAnalyticsState();
}

class _ExpenseAnalyticsState extends State<ExpenseAnalytics> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, double> _expenseCategoryData = {};
  Map<String, double> _incomeCategoryData = {};
  Map<DateTime, double> _dailyExpenseData = {};
  Map<DateTime, double> _dailyIncomeData = {};
  
  // Stats
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  String? _topExpenseCategory;
  double _topExpenseAmount = 0;
  double _averageDailyExpense = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _processTransactionData();
  }
  
  @override
  void didUpdateWidget(ExpenseAnalytics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions != oldWidget.transactions ||
        widget.startDate != oldWidget.startDate ||
        widget.endDate != oldWidget.endDate) {
      _processTransactionData();
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _processTransactionData() {
    // Filter transactions by date range
    final filteredTransactions = widget.transactions.where((transaction) {
      return transaction.date.isAfter(widget.startDate.subtract(const Duration(days: 1))) &&
             transaction.date.isBefore(widget.endDate.add(const Duration(days: 1)));
    }).toList();
    
    // Reset data
    _expenseCategoryData = {};
    _incomeCategoryData = {};
    _dailyExpenseData = {};
    _dailyIncomeData = {};
    _totalIncome = 0;
    _totalExpense = 0;
    _topExpenseCategory = null;
    _topExpenseAmount = 0;
    
    // Process each transaction
    for (final transaction in filteredTransactions) {
      final categoryName = widget.categoryNames[transaction.category] ?? transaction.category;
      final date = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      
      if (transaction.type == model.TransactionType.expense) {
        // Add to category data
        _expenseCategoryData[categoryName] = 
            (_expenseCategoryData[categoryName] ?? 0) + transaction.amount;
        
        // Add to daily data
        _dailyExpenseData[date] = (_dailyExpenseData[date] ?? 0) + transaction.amount;
        
        // Update total
        _totalExpense += transaction.amount;
      } else {
        // Add to category data
        _incomeCategoryData[categoryName] = 
            (_incomeCategoryData[categoryName] ?? 0) + transaction.amount;
        
        // Add to daily data
        _dailyIncomeData[date] = (_dailyIncomeData[date] ?? 0) + transaction.amount;
        
        // Update total
        _totalIncome += transaction.amount;
      }
    }
    
    // Calculate balance
    _balance = _totalIncome - _totalExpense;
    
    // Find top expense category
    if (_expenseCategoryData.isNotEmpty) {
      String topCategory = _expenseCategoryData.keys.first;
      double topAmount = _expenseCategoryData.values.first;
      
      for (final entry in _expenseCategoryData.entries) {
        if (entry.value > topAmount) {
          topCategory = entry.key;
          topAmount = entry.value;
        }
      }
      
      _topExpenseCategory = topCategory;
      _topExpenseAmount = topAmount;
    }
    
    // Calculate average daily expense
    if (_dailyExpenseData.isNotEmpty) {
      _averageDailyExpense = _totalExpense / _dailyExpenseData.length;
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSummaryCards(),
        
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Trends'),
          ],
        ),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildCategoriesTab(),
              _buildTrendsTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Income',
                  amount: _totalIncome,
                  icon: Icons.arrow_downward,
                  color: AppTheme.incomeColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Expenses',
                  amount: _totalExpense,
                  icon: Icons.arrow_upward,
                  color: AppTheme.expenseColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'Balance',
            amount: _balance,
            icon: Icons.account_balance_wallet,
            color: _balance >= 0 ? Colors.blue : Colors.red,
            isExpanded: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    bool isExpanded = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: isExpanded ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(symbol: '\$').format(amount),
              style: TextStyle(
                fontSize: isExpanded ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: isExpanded ? TextAlign.center : TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    final dateFormatter = DateFormat('MMM d, yyyy');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview for ${dateFormatter.format(widget.startDate)} - ${dateFormatter.format(widget.endDate)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Key stats
          _buildStatCard(
            title: 'Top Expense Category',
            value: _topExpenseCategory != null 
                ? '$_topExpenseCategory (${NumberFormat.currency(symbol: '\$').format(_topExpenseAmount)})'
                : 'No expenses',
            icon: Icons.category,
            color: AppTheme.expenseColor,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            title: 'Average Daily Expense',
            value: NumberFormat.currency(symbol: '\$').format(_averageDailyExpense),
            icon: Icons.calendar_today,
            color: AppTheme.expenseColor,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            title: 'Expense to Income Ratio',
            value: _totalIncome > 0 
                ? '${NumberFormat.percentPattern().format(_totalExpense / _totalIncome)}'
                : 'N/A',
            icon: Icons.pie_chart,
            color: _totalExpense < _totalIncome ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            title: 'Savings Rate',
            value: _totalIncome > 0 
                ? '${NumberFormat.percentPattern().format((_totalIncome - _totalExpense) / _totalIncome)}'
                : 'N/A',
            icon: Icons.savings,
            color: Colors.blue,
          ),
          
          const SizedBox(height: 32),
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Recent activity
          _buildRecentActivity(),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentActivity() {
    // Sort transactions by date (newest first)
    final sortedTransactions = widget.transactions
        .where((transaction) {
          return transaction.date.isAfter(widget.startDate.subtract(const Duration(days: 1))) &&
                 transaction.date.isBefore(widget.endDate.add(const Duration(days: 1)));
        })
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    // Take last 5 transactions
    final recentTransactions = sortedTransactions.take(5).toList();
    
    if (recentTransactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No recent transactions'),
        ),
      );
    }
    
    return Column(
      children: recentTransactions.map((transaction) {
        final categoryName = widget.categoryNames[transaction.category] ?? transaction.category;
        final isExpense = transaction.type == model.TransactionType.expense;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isExpense 
                    ? AppTheme.expenseColor.withOpacity(0.1)
                    : AppTheme.incomeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
              ),
            ),
            title: Text(transaction.title),
            subtitle: Text(categoryName),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(symbol: '\$').format(transaction.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(transaction.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Expense pie chart
          if (_expenseCategoryData.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No expense data for this period'),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: CategoryPieChart(
                categoryData: _expenseCategoryData,
                isExpense: true,
              ),
            ),
          
          const SizedBox(height: 32),
          const Text(
            'Income Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Income pie chart
          if (_incomeCategoryData.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No income data for this period'),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: CategoryPieChart(
                categoryData: _incomeCategoryData,
                isExpense: false,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Trends',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            height: 300,
            child: _buildDailyChart(),
          ),
          
          const SizedBox(height: 32),
          const Text(
            'Income vs Expense',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 300,
            child: _buildComparisonChart(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDailyChart() {
    // Create a list of all dates in the range
    final days = <DateTime>[];
    DateTime currentDate = widget.startDate;
    while (currentDate.isBefore(widget.endDate.add(const Duration(days: 1)))) {
      days.add(DateTime(currentDate.year, currentDate.month, currentDate.day));
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    // Create line chart data
    final expenseSpots = days.map((date) {
      final amount = _dailyExpenseData[date] ?? 0;
      final index = days.indexOf(date).toDouble();
      return FlSpot(index, amount);
    }).toList();
    
    final incomeSpots = days.map((date) {
      final amount = _dailyIncomeData[date] ?? 0;
      final index = days.indexOf(date).toDouble();
      return FlSpot(index, amount);
    }).toList();
    
    return days.isEmpty
        ? const Center(child: Text('No data for selected date range'))
        : LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= days.length) {
                        return const Text('');
                      }
                      final date = days[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(DateFormat('MM/dd').format(date)),
                      );
                    },
                    interval: days.length > 7 ? (days.length / 7).ceilToDouble() : 1,
                  ),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  color: AppTheme.expenseColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.expenseColor.withOpacity(0.1),
                  ),
                ),
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  color: AppTheme.incomeColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.incomeColor.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          );
  }
  
  Widget _buildComparisonChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _totalIncome > _totalExpense ? _totalIncome : _totalExpense,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final amount = groupIndex == 0 ? _totalIncome : _totalExpense;
              return BarTooltipItem(
                NumberFormat.currency(symbol: '\$').format(amount),
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    value.toInt() == 0 ? 'Income' : 'Expense',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: _totalIncome,
                color: AppTheme.incomeColor,
                width: 60,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: _totalExpense,
                color: AppTheme.expenseColor,
                width: 60,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 