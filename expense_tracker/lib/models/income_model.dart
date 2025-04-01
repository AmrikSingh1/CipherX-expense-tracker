import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class IncomeModel {
  final String id;
  final String userId;
  final double amount;
  final String source;
  final DateTime date;
  final String description;
  final bool isRecurring;
  final String? frequency;
  final DateTime createdAt;
  final DateTime updatedAt;

  IncomeModel({
    String? id,
    required this.userId,
    required this.amount,
    required this.source,
    required this.date,
    required this.description,
    this.isRecurring = false,
    this.frequency,
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
      'amount': amount,
      'source': source,
      'date': date,
      'description': description,
      'isRecurring': isRecurring,
      'frequency': frequency,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'source': source,
      'date': Timestamp.fromDate(date),
      'description': description,
      'isRecurring': isRecurring,
      'frequency': frequency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory IncomeModel.fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      source: map['source'] ?? 'Other',
      date: map['date'] is DateTime 
            ? map['date'] 
            : (map['date'] is Timestamp 
              ? (map['date'] as Timestamp).toDate() 
              : (map['date'] != null 
                ? DateTime.fromMillisecondsSinceEpoch(map['date']) 
                : DateTime.now())),
      description: map['description'] ?? '',
      isRecurring: map['isRecurring'] ?? false,
      frequency: map['frequency'],
      createdAt: map['createdAt'] is DateTime 
                ? map['createdAt'] 
                : (map['createdAt'] is Timestamp 
                  ? (map['createdAt'] as Timestamp).toDate() 
                  : (map['createdAt'] != null 
                    ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
                    : DateTime.now())),
      updatedAt: map['updatedAt'] is DateTime 
                ? map['updatedAt'] 
                : (map['updatedAt'] is Timestamp 
                  ? (map['updatedAt'] as Timestamp).toDate() 
                  : (map['updatedAt'] != null 
                    ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) 
                    : DateTime.now())),
    );
  }

  factory IncomeModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return IncomeModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      source: data['source'] ?? 'Other',
      date: data['date'] != null 
            ? (data['date'] is Timestamp 
              ? data['date'].toDate() 
              : DateTime.now()) 
            : DateTime.now(),
      description: data['description'] ?? '',
      isRecurring: data['isRecurring'] ?? false,
      frequency: data['frequency'],
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