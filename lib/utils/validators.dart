import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Will be handled by context-aware validators
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return null; // Will be handled by context-aware validators
    }
    return null;
  }

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName ?? 'This field is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Will be handled by context-aware validators
    }
    // Remove all non-digit characters to check length
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 10) {
      return null; // Will be handled by context-aware validators
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Will be handled by context-aware validators
    }
    if (value.length < 6) {
      return null; // Will be handled by context-aware validators
    }
    return null;
  }

  // Context-aware validators that use translations
  static String? emailValidated(String? value, BuildContext context) {
    final langService = Provider.of<LanguageService>(context, listen: false);
    if (value == null || value.isEmpty) {
      return langService.getString('student_form.validators.email');
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return langService.getString('student_form.validators.invalid_email');
    }
    return null;
  }

  static String? phoneValidated(String? value, BuildContext context) {
    final langService = Provider.of<LanguageService>(context, listen: false);
    if (value == null || value.isEmpty) {
      return langService.getString('student_form.validators.phone');
    }
    // Remove all non-digit characters to check length
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 10) {
      return langService.getString('student_form.validators.invalid_phone');
    }
    return null;
  }

  static String? passwordValidated(String? value, BuildContext context) {
    final langService = Provider.of<LanguageService>(context, listen: false);
    if (value == null || value.isEmpty) {
      return langService.getString('student_form.validators.password');
    }
    if (value.length < 6) {
      return langService
          .getString('student_form.validators.password_min_length');
    }
    return null;
  }

  static String? minLength(String? value, int min) {
    if (value == null || value.length < min) {
      return 'Must be at least $min characters';
    }
    return null;
  }
}
