import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class AuthService {
  User? _currentUser;
  DateTime? _lastActivity;
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _lastActivityKey = 'last_activity';

  // Get current user
  User? get currentUser => _currentUser;

  // Check if user is logged in and session is not expired
  bool get isLoggedIn {
    if (Supabase.instance.client.auth.currentUser == null) {
      return false;
    }

    // Check for session timeout
    if (_isSessionExpired()) {
      signOut();
      return false;
    }

    _updateLastActivity();
    return true;
  }

  // Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = User(
          id: response.user!.id,
          email: response.user!.email ?? email,
          name: response.user!.userMetadata?['name'] ?? 'Admin User',
        );
        await _saveLoginState();
      } else {
        throw Exception('Authentication failed');
      }
    } catch (e) {
      throw Exception('Invalid email or password');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      // Ignore signout errors
    }
    _currentUser = null;
    await _clearLoginState();
  }

  // Check if current user is admin
  bool get isAdmin {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    // Don't check session timeout here to avoid logout loops

    // Verify admin role in both userMetadata and appMetadata
    final userRole = user.userMetadata?['role'] as String?;
    final appRole = user.appMetadata?['role'] as String?;

    // Check for admin role in metadata
    final isUserAdmin = userRole?.toLowerCase().trim() == 'admin';
    final isAppAdmin = appRole?.toLowerCase().trim() == 'admin';

    // Basic email validation
    final email = user.email?.toLowerCase() ?? '';
    final hasValidEmail = email.isNotEmpty && email.contains('@');

    return (isUserAdmin || isAppAdmin) && hasValidEmail;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Failed to send password reset email');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && isAdmin) {
      // Only return profile data for verified admin users
      return {
        'id': user.id,
        'email': user.email,
        'name': user.userMetadata?['name'] ?? 'Admin User',
        'role':
            user.userMetadata?['role'] ?? user.appMetadata?['role'] ?? 'user',
        'last_sign_in': user.lastSignInAt,
        'email_confirmed': user.emailConfirmedAt != null,
      };
    }
    return null;
  }

  // Initialize auth state
  Future<void> initialize() async {
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session?.user != null) {
        _currentUser = User(
          id: session!.user.id,
          email: session.user.email ?? '',
          name: session.user.userMetadata?['name'] ?? 'Admin User',
        );
      } else {
        _currentUser = null;
      }
    });

    await _loadLoginState();
  }

  // Check if session has expired
  bool _isSessionExpired() {
    if (_lastActivity == null) return false; // Allow first login

    final now = DateTime.now();
    final sessionTimeout = Duration(seconds: AppConfig.sessionTimeout);

    // Additional check: validate Supabase session expiry
    final session = Supabase.instance.client.auth.currentSession;
    if (session?.expiresAt != null) {
      final sessionExpiry =
          DateTime.fromMillisecondsSinceEpoch(session!.expiresAt! * 1000);
      if (now.isAfter(sessionExpiry)) {
        return true;
      }
    }

    return now.difference(_lastActivity!) > sessionTimeout;
  }

  // Update last activity timestamp
  void _updateLastActivity() {
    _lastActivity = DateTime.now();
    _saveLastActivity();
  }

  // Save last activity to storage
  Future<void> _saveLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastActivity != null) {
        await prefs.setString(
            _lastActivityKey, _lastActivity!.toIso8601String());
      }
    } catch (e) {
      // Ignore save errors
    }
  }

  // Load last activity from storage
  Future<void> _loadLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityString = prefs.getString(_lastActivityKey);

      if (lastActivityString != null) {
        _lastActivity = DateTime.parse(lastActivityString);
      }
    } catch (e) {
      _lastActivity = null;
    }
  }

  // Save login state to persistent storage
  Future<void> _saveLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null) {
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        _updateLastActivity();
      }
    } catch (e) {
      // Ignore save errors
    }
  }

  // Load login state from persistent storage
  Future<void> _loadLoginState() async {
    try {
      // Supabase handles session persistence automatically
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _currentUser = User(
          id: user.id,
          email: user.email ?? '',
          name: user.userMetadata?['name'] ?? 'Admin User',
        );
      }

      await _loadLastActivity();
    } catch (e) {
      await _clearLoginState();
    }
  }

  // Clear login state from persistent storage
  Future<void> _clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userKey);
      await prefs.remove(_lastActivityKey);
      _lastActivity = null;
    } catch (e) {
      // Ignore clear errors
    }
  }
}

// User class
class User {
  User({required this.id, required this.email, this.name});

  // Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
      );
  final String id;
  final String email;
  final String? name;

  // Convert User to JSON
  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name};
}
