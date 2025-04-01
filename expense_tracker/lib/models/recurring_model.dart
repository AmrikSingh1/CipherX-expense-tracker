import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/models/transaction_model.dart' as model;

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly
}

class RecurringTransaction {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String category;
  final model.TransactionType type;
  final String? note;
  final String? paymentMethod;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastProcessed;

  RecurringTransaction({
    String? id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.note,
    this.paymentMethod,
    this.isActive = true,
    this.lastProcessed,
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
      'category': category,
      'type': type.index,
      'note': note,
      'paymentMethod': paymentMethod,
      'frequency': frequency.index,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastProcessed': lastProcessed,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type.index,
      'note': note,
      'paymentMethod': paymentMethod,
      'frequency': frequency.index,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastProcessed': lastProcessed != null ? Timestamp.fromDate(lastProcessed!) : null,
    };
  }

  factory RecurringTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return RecurringTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? 'Others',
      type: data['type'] != null 
            ? model.TransactionType.values[data['type']] 
            : model.TransactionType.expense,
      note: data['note'],
      paymentMethod: data['paymentMethod'],
      frequency: data['frequency'] != null 
                ? RecurrenceFrequency.values[data['frequency']] 
                : RecurrenceFrequency.monthly,
      startDate: data['startDate'] != null 
                ? (data['startDate'] as Timestamp).toDate()
                : DateTime.now(),
      endDate: data['endDate'] != null 
              ? (data['endDate'] as Timestamp).toDate()
              : null,
      isActive: data['isActive'] ?? true,
      lastProcessed: data['lastProcessed'] != null 
                    ? (data['lastProcessed'] as Timestamp).toDate()
                    : null,
      createdAt: data['createdAt'] != null 
                ? (data['createdAt'] as Timestamp).toDate() 
                : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
                ? (data['updatedAt'] as Timestamp).toDate() 
                : DateTime.now(),
    );
  }

  // Get the due date for the next recurrence
  DateTime getNextDueDate() {
    DateTime baseDate = lastProcessed ?? startDate;
    
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return baseDate.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return baseDate.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        // Move to the next month, keeping the same day
        return DateTime(
          baseDate.year + (baseDate.month == 12 ? 1 : 0),
          baseDate.month == 12 ? 1 : baseDate.month + 1,
          baseDate.day,
        );
      case RecurrenceFrequency.quarterly:
        // Move 3 months forward
        int newMonth = baseDate.month + 3;
        int yearIncrement = 0;
        
        if (newMonth > 12) {
          newMonth = newMonth - 12;
          yearIncrement = 1;
        }
        
        return DateTime(
          baseDate.year + yearIncrement,
          newMonth,
          baseDate.day,
        );
      case RecurrenceFrequency.yearly:
        return DateTime(
          baseDate.year + 1,
          baseDate.month,
          baseDate.day,
        );
    }
  }

  // Check if the transaction is due for processing
  bool isDue() {
    if (!isActive) return false;
    
    final DateTime now = DateTime.now();
    
    // Check if end date has passed
    if (endDate != null && endDate!.isBefore(now)) {
      return false;
    }
    
    // If never processed, check if start date has passed
    if (lastProcessed == null) {
      return startDate.isBefore(now);
    }
    
    // Otherwise, check if next due date has passed
    return getNextDueDate().isBefore(now);
  }

  // Create a Transaction from this recurring transaction
  model.Transaction toTransaction() {
    return model.Transaction(
      userId: userId,
      title: title,
      amount: amount,
      date: DateTime.now(),
      category: category,
      type: type,
      note: note,
      paymentMethod: paymentMethod,
      isRecurring: true,
    );
  }

  // Create a copy with updated fields
  RecurringTransaction copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    String? category,
    model.TransactionType? type,
    String? note,
    String? paymentMethod,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? lastProcessed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      lastProcessed: lastProcessed ?? this.lastProcessed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Updates the last processed date to now
  RecurringTransaction markProcessed() {
    return copyWith(
      lastProcessed: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
} 