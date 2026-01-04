import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      await _loadUserProfile();
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    if (_firebaseUser == null) return;
    _userModel = await _firestoreService.getUserProfile(_firebaseUser!.uid);
  }

  // Kayıt ol
  Future<bool> register(String email, String password, String displayName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.registerWithEmail(email, password);
      
      // Kullanıcı profili oluştur
      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createUserProfile(user);
      _userModel = user;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Giriş yap
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmail(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Şifre sıfırla
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    notifyListeners();
  }

  // Profil güncelle
  Future<void> updateProfile({
    String? displayName,
    String? department,
    String? grade,
    String? photoUrl,
  }) async {
    if (_firebaseUser == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (department != null) updates['department'] = department;
    if (grade != null) updates['grade'] = grade;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    await _firestoreService.updateUserProfile(_firebaseUser!.uid, updates);
    await _loadUserProfile();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
