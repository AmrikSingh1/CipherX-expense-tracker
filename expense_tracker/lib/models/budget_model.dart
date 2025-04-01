import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id; // Document ID
  final String userId;
  final double amount;
  final String period; // 'monthly', 'weekly', etc.
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, double>? categories;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.categories,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'period': period,
      'startDate': startDate,
      'endDate': endDate,
      'categories': categories,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'period': period,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'categories': categories,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle categories map conversion
    Map<String, double>? categoriesMap;
    if (map['categories'] != null) {
      categoriesMap = Map<String, double>.from(
        map['categories'].map((key, value) => MapEntry(key, value.toDouble()))
      );
    }

    return BudgetModel(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      period: map['period'] ?? 'monthly',
      startDate: map['startDate'] != null 
                ? (map['startDate'] is DateTime 
                  ? map['startDate'] 
                  : (map['startDate'] is Timestamp 
                    ? map['startDate'].toDate() 
                    : DateTime.now())) 
                : DateTime.now(),
      endDate: map['endDate'] != null 
              ? (map['endDate'] is DateTime 
                ? map['endDate'] 
                : (map['endDate'] is Timestamp 
                  ? map['endDate'].toDate() 
                  : DateTime.now().add(const Duration(days: 30)))) 
              : DateTime.now().add(const Duration(days: 30)),
      categories: categoriesMap,
      notes: map['notes'],
      createdAt: map['createdAt'] != null 
                ? (map['createdAt'] is DateTime 
                  ? map['createdAt'] 
                  : (map['createdAt'] is Timestamp 
                    ? map['createdAt'].toDate() 
                    : DateTime.now())) 
                : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
                ? (map['updatedAt'] is DateTime 
                  ? map['updatedAt'] 
                  : (map['updatedAt'] is Timestamp 
                    ? map['updatedAt'].toDate() 
                    : DateTime.now())) 
                : DateTime.now(),
    );
  }

  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Handle categories map conversion
    Map<String, double>? categoriesMap;
    if (data['categories'] != null) {
      categoriesMap = Map<String, double>.from(
        data['categories'].map((key, value) => MapEntry(key, (value ?? 0).toDouble()))
      );
    }

    return BudgetModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      period: data['period'] ?? 'monthly',
      startDate: data['startDate'] != null 
                ? (data['startDate'] is Timestamp 
                  ? data['startDate'].toDate() 
                  : DateTime.now()) 
                : DateTime.now(),
      endDate: data['endDate'] != null 
              ? (data['endDate'] is Timestamp 
                ? data['endDate'].toDate() 
                : DateTime.now().add(const Duration(days: 30))) 
              : DateTime.now().add(const Duration(days: 30)),
      categories: categoriesMap,
      notes: data['notes'],
      createdAt: data['createdAt'] != null 
                ? (data['createdAt'] is Timestamp 
                  ? data['createdAt'].toDate() 
                  : DateTime.now()) 
                : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
                ? (data['updatedAt'] is Timestamp 
                  ? data['updatedAt'].toDate() 
                  : DateTime.now()) 
                : DateTime.now(),
    );
  }
} 