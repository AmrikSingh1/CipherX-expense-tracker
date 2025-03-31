import 'package:uuid/uuid.dart';

enum TransactionType { income, expense }

class TransactionCategory {
  static const List<String> expenseCategories = [
    'Food',
    'Transportation',
    'Housing',
    'Entertainment',
    'Shopping',
    'Utilities',
    'Health',
    'Education',
    'Travel',
    'Subscriptions',
    'Others'
  ];

  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Investments',
    'Gifts',
    'Refunds',
    'Others'
  ];
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final TransactionType type;
  final String? note;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.note,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'type': type.index,
      'note': note,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      category: map['category'],
      type: TransactionType.values[map['type']],
      note: map['note'],
    );
  }
} 