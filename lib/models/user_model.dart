import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // "admin" or "customer"
  final String? assignedService; // For admins: Clinic, Salon, etc.
  final DateTime createdAt;
  final String? phoneNumber;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.assignedService,
    required this.createdAt,
    this.phoneNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
      assignedService: map['assignedService'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      phoneNumber: map['phoneNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'assignedService': assignedService,
      'createdAt': Timestamp.fromDate(createdAt),
      'phoneNumber': phoneNumber,
    };
  }
}
