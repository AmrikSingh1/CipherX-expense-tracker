import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class FormatUtils {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  /// Format a number as currency
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }
  
  // Format date
  static String formatDate(DateTime date, {String format = 'MMM d, yyyy'}) {
    return DateFormat(format).format(date);
  }
  
  // Format time
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }
  
  // Format date and time
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }
  
  // Get color for transaction type
  static Color getTransactionColor(bool isIncome) {
    return isIncome ? Colors.green.shade600 : Colors.red.shade600;
  }
  
  /// Format a date range as a string
  static String formatDateRange(DateTime start, DateTime end) {
    final startStr = DateFormat('MMM d').format(start);
    final endStr = DateFormat('MMM d, yyyy').format(end);
    return '$startStr - $endStr';
  }
  
  /// Format a number with commas for thousands
  static String formatNumber(num number) {
    return NumberFormat.decimalPattern().format(number);
  }
  
  /// Format a percentage
  static String formatPercentage(double percentage) {
    return NumberFormat.percentPattern().format(percentage / 100);
  }
  
  // Shorten text with ellipsis if it's too long
  static String shortenText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
} 