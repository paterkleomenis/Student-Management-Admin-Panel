import 'package:flutter/material.dart' show ChangeNotifier;
import '../models/student.dart';
import '../services/student_service.dart';

class AppProvider with ChangeNotifier {
  final StudentService _studentService = StudentService();

  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Student data
  List<Student> _students = [];
  List<Student> get students => _students;

  Map<String, dynamic> _stats = {};
  Map<String, dynamic> get stats => _stats;

  // Error handling
  String? _error;
  String? get error => _error;

  // Methods
  Future<void> loadStudents() async {
    _setLoading(true);
    try {
      _students = await _studentService.getStudents();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadStatistics() async {
    try {
      _stats = await _studentService.getStatistics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
