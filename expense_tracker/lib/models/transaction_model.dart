import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String userId;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final TransactionType type;
  final String? note;
  final String? paymentMethod;
  final bool isRecurring;
  final String? attachmentUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    String? id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.note,
    this.paymentMethod,
    this.isRecurring = false,
    this.attachmentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'date': date,
      'category': category,
      'type': type.index,
      'note': note,
      'paymentMethod': paymentMethod,
      'isRecurring': isRecurring,
      'attachmentUrl': attachmentUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'type': type.index,
      'description': note, // Map 'note' to 'description' in Firestore
      'paymentMethod': paymentMethod,
      'isRecurring': isRecurring,
      'attachmentUrl': attachmentUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      userId: map['userId'] ?? '',
      title: map['title'],
      amount: map['amount'],
      date: map['date'] is DateTime 
            ? map['date'] 
            : DateTime.fromMillisecondsSinceEpoch(map['date']),
      category: map['category'],
      type: TransactionType.values[map['type']],
      note: map['note'],
      paymentMethod: map['paymentMethod'],
      isRecurring: map['isRecurring'] ?? false,
      attachmentUrl: map['attachmentUrl'],
      createdAt: map['createdAt'] is DateTime 
                ? map['createdAt'] 
                : (map['createdAt'] != null 
                  ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
                  : DateTime.now()),
      updatedAt: map['updatedAt'] is DateTime 
                ? map['updatedAt'] 
                : (map['updatedAt'] != null 
                  ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) 
                  : DateTime.now()),
    );
  }

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Use Firestore document ID if 'id' field is missing
    String id = data['id'] ?? doc.id;
    
    print('Transaction.fromFirestore - Doc ID: ${doc.id}, Field ID: ${data['id']}');
    return Transaction(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? data['description'] ?? '', // Support both title and description fields
      amount: (data['amount'] ?? 0).toDouble(),
      date: data['date'] != null 
            ? (data['date'] is Timestamp 
              ? data['date'].toDate() 
              : DateTime.fromMillisecondsSinceEpoch(data['date']))
            : DateTime.now(),
      category: data['category'] ?? 'Others',
      type: data['type'] != null 
            ? TransactionType.values[data['type']] 
            : TransactionType.expense,
      note: data['note'] ?? data['description'],
      paymentMethod: data['paymentMethod'],
      isRecurring: data['isRecurring'] ?? false,
      attachmentUrl: data['attachmentUrl'],
      createdAt: data['createdAt'] != null 
                ? (data['createdAt'] is Timestamp 
                  ? data['createdAt'].toDate() 
                  : DateTime.fromMillisecondsSinceEpoch(data['createdAt'])) 
                : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
                ? (data['updatedAt'] is Timestamp 
                  ? data['updatedAt'].toDate() 
                  : DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])) 
                : DateTime.now(),
    );
  }
} 