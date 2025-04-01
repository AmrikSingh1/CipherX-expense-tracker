import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id; // Document ID, same as category slug
  final String name;
  final String icon;
  final String color;
  final double? budget;
  final bool isDefault;
  final String? createdBy;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budget,
    this.isDefault = false,
    this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'budget': budget,
      'isDefault': isDefault,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'budget': budget,
      'isDefault': isDefault,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? 'Unknown',
      icon: map['icon'] ?? 'question_mark',
      color: map['color'] ?? '#000000',
      budget: map['budget']?.toDouble(),
      isDefault: map['isDefault'] ?? false,
      createdBy: map['createdBy'],
      createdAt: map['createdAt'] != null 
                ? (map['createdAt'] is DateTime 
                  ? map['createdAt'] 
                  : (map['createdAt'] is Timestamp 
                    ? map['createdAt'].toDate() 
                    : DateTime.now())) 
                : DateTime.now(),
    );
  }

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      icon: data['icon'] ?? 'question_mark',
      color: data['color'] ?? '#000000',
      budget: data['budget']?.toDouble(),
      isDefault: data['isDefault'] ?? false,
      createdBy: data['createdBy'],
      createdAt: data['createdAt'] != null 
                ? (data['createdAt'] is Timestamp 
                  ? data['createdAt'].toDate() 
                  : DateTime.now()) 
                : DateTime.now(),
    );
  }
} 