import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class AuthService {
  User? _currentUser;
  static bool get _useSupabase => AppConfig.useSupabaseAuth;
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  // Get current user
  User? get currentUser => _currentUser;

  // Check if user is logged in
  bool get isLoggedIn =>
      _currentUser != null ||
      (_useSupabase && Supabase.instance.client.auth.currentUser != null);

  // Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_useSupabase) {
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
        if (AppConfig.enableLogging) {
          debugPrint('Supabase auth error: $e');
        }
        throw Exception('Invalid email or password');
      }
    } else {
      // Fallback to more secure mock authentication
      await _secureSignIn(email, password);
    }
  }

  // More secure mock sign in (temporary, for development only)
  Future<void> _secureSignIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    // Generate a more secure temporary password check
    final expectedHash = _simpleHash('admin@admin.com:SecurePass123!');
    final providedHash = _simpleHash('$email:$password');

    if (providedHash == expectedHash) {
      _currentUser = User(
        id: _generateSecureId(),
        email: email,
        name: 'Admin User',
      );
      await _saveLoginState();
    } else {
      throw Exception('Invalid email or password');
    }
  }

  // Simple hash function for development (NOT for production)
  String _simpleHash(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xffffffff;
    }
    return hash.toString();
  }

  // Generate a secure session ID
  String _generateSecureId() {
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        16,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Sign out
  Future<void> signOut() async {
    if (_useSupabase) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        if (AppConfig.enableLogging) {
          debugPrint('Supabase signout error: $e');
        }
      }
    }
    _currentUser = null;
    await _clearLoginState();
  }

  // Check if current user is admin
  bool get isAdmin {
    if (_useSupabase) {
      final user = Supabase.instance.client.auth.currentUser;
      return user != null &&
          (user.userMetadata?['role'] == 'admin' ||
              user.email?.contains('admin') == true);
    }
    return _currentUser != null;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    if (_useSupabase) {
      try {
        await Supabase.instance.client.auth.resetPasswordForEmail(email);
      } catch (e) {
        if (AppConfig.enableLogging) {
          debugPrint('Password reset error: $e');
        }
        throw Exception('Failed to send password reset email');
      }
    } else {
      await Future.delayed(const Duration(seconds: 1));
      // Mock password reset
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_useSupabase) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        return {
          'id': user.id,
          'email': user.email,
          'name': user.userMetadata?['name'] ?? 'Admin User',
          'role': user.userMetadata?['role'] ?? 'admin',
        };
      }
    } else if (_currentUser != null) {
      return {
        'id': _currentUser!.id,
        'email': _currentUser!.email,
        'name': _currentUser!.name,
        'role': 'admin',
      };
    }
    return null;
  }

  // Initialize auth state
  Future<void> initialize() async {
    if (_useSupabase) {
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
    }

    // Load saved login state for fallback mode
    await _loadLoginState();
  }

  // Save login state to persistent storage
  Future<void> _saveLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null) {
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        debugPrint('Error saving login state: $e');
      }
    }
  }

  // Load login state from persistent storage
  Future<void> _loadLoginState() async {
    try {
      if (_useSupabase) {
        // Supabase handles session persistence automatically
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          _currentUser = User(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['name'] ?? 'Admin User',
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

      if (isLoggedIn) {
        final userJson = prefs.getString(_userKey);
        if (userJson != null) {
          final userData = jsonDecode(userJson) as Map<String, dynamic>;
          _currentUser = User.fromJson(userData);
        }
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        debugPrint('Error loading login state: $e');
      }
      await _clearLoginState();
    }
  }

  // Clear login state from persistent storage
  Future<void> _clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userKey);
    } catch (e) {
      if (AppConfig.enableLogging) {
        debugPrint('Error clearing login state: $e');
      }
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
