import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String _role = 'customer';

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get role => _role;

  AppAuthProvider() {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
    }
  }

  Future<void> _loadUserData(String uid) async {
    _isLoading = true;
    notifyListeners();
    
    _currentUser = await _authService.getUserModel(uid);
    if (_currentUser != null) {
      _role = _currentUser!.role;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      UserCredential result = await _authService.signInWithEmail(email, password);
      if (result.user != null) {
        await _loadUserData(result.user!.uid);
      }
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? assignedService,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      UserCredential result = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      
      if (result.user != null) {
        // If it's an admin, update the Firestore record with the assigned service
        if (role == 'admin' && assignedService != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(result.user!.uid)
              .update({'assignedService': assignedService});
        }
        await _loadUserData(result.user!.uid);
      }
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    _role = 'customer';
    notifyListeners();
  }
}
