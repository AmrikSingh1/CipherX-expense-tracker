import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final String? phoneNumber;
  final Map<String, dynamic>? settings;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    DateTime? createdAt,
    this.phoneNumber,
    this.settings,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'phoneNumber': phoneNumber,
      'settings': settings,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? map['id'],
      name: map['name'] ?? 'User',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null 
        ? (map['createdAt'] is DateTime 
          ? map['createdAt'] 
          : (map['createdAt'].toDate())) 
        : DateTime.now(),
      phoneNumber: map['phoneNumber'],
      settings: map['settings'],
    );
  }

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      phoneNumber: user.phoneNumber,
    );
  }
} 