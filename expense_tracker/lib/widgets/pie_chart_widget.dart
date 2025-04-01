import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/utils/format_utils.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> categoryData;
  final bool isExpense;

  const CategoryPieChart({
    super.key,
    required this.categoryData,
    this.isExpense = true,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return Center(
        child: Text(
          'No ${isExpense ? 'expense' : 'income'} data available',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    final List<Color> colors = isExpense ? _expenseColors : _incomeColors;
    final double total = categoryData.values.fold(0, (sum, item) => sum + item);

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _generateSections(categoryData, colors, total),
              pieTouchData: PieTouchData(
                enabled: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _buildLegend(categoryData, colors, total),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generateSections(
    Map<String, double> data,
    List<Color> colors,
    double total,
  ) {
    final List<PieChartSectionData> sections = [];
    
    int colorIndex = 0;
    data.forEach((category, amount) {
      final double percentage = amount / total;
      
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: FormatUtils.formatPercentage(percentage),
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      
      colorIndex++;
    });
    
    return sections;
  }
  
  List<Widget> _buildLegend(
    Map<String, double> data,
    List<Color> colors,
    double total,
  ) {
    final List<Widget> legends = [];
    
    int colorIndex = 0;
    data.forEach((category, amount) {
      final double percentage = amount / total;
      final Color color = colors[colorIndex % colors.length];
      
      legends.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${FormatUtils.shortenText(category, 12)} (${FormatUtils.formatPercentage(percentage)})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
      
      colorIndex++;
    });
    
    return legends;
  }
  
  // Expense category colors
  static const List<Color> _expenseColors = [
    Color(0xFFF44336), // Red
    Color(0xFFFF9800), // Orange
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF4CAF50), // Green
    Color(0xFF2196F3), // Blue
    Color(0xFF9C27B0), // Purple
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
    Color(0xFF009688), // Teal
    Color(0xFFCDDC39), // Lime
  ];
  
  // Income category colors
  static const List<Color> _incomeColors = [
    Color(0xFF4CAF50), // Green
    Color(0xFF8BC34A), // Light Green
    Color(0xFF00BCD4), // Cyan
    Color(0xFF03A9F4), // Light Blue
    Color(0xFF3F51B5), // Indigo
    Color(0xFF673AB7), // Deep Purple
  ];
} 