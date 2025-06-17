// lib/providers/login_provider.dart
import 'package:flutter/material.dart';

class LoginProvider with ChangeNotifier {
  String? _errorMessage;
  bool _isLoading = false; // Add loading state

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading; // Getter for loading state

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Modified login method: no longer takes BuildContext for navigation
  Future<void> login(String email, String password) async {
    _setLoading(true); // Start loading

    // Clear previous error message
    _errorMessage = null;
    notifyListeners(); // Notify listeners to clear the error message immediately

    // Simulate network delay or Firebase authentication
    // In a real app, you would replace this with actual Firebase Auth logic
    await Future.delayed(const Duration(seconds: 2));

    if (email == "admin" && password == "admin") {
      // Login successful
      _errorMessage = null; // Ensure error is null on success
    } else {
      // Login failed
      _errorMessage = "Invalid Username or Password";
    }

    _setLoading(false); // Stop loading after operation
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}