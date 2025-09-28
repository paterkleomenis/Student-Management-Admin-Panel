import 'package:flutter/material.dart' show ChangeNotifier;
import '../models/student.dart';
import '../models/student_receipt.dart';
import '../services/receipt_service.dart';
import '../services/student_service.dart';

class ReceiptProvider with ChangeNotifier {
  final ReceiptService _receiptService = ReceiptService();
  final StudentService _studentService = StudentService();

  // Loading states
  bool _isLoadingStudents = false;
  bool _isLoadingReceipts = false;
  bool _isUploading = false;

  bool get isLoadingStudents => _isLoadingStudents;
  bool get isLoadingReceipts => _isLoadingReceipts;
  bool get isUploading => _isUploading;

  // Data
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  List<StudentReceipt> _receipts = [];
  Student? _selectedStudent;
  Map<String, dynamic> _statistics = {};

  List<Student> get students => _students;
  List<Student> get filteredStudents => _filteredStudents;
  List<StudentReceipt> get receipts => _receipts;
  Student? get selectedStudent => _selectedStudent;
  Map<String, dynamic> get statistics => _statistics;

  // Search and filter
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Error handling
  String? _error;
  String? get error => _error;

  // Load all students
  Future<void> loadStudents() async {
    _setLoadingStudents(true);
    try {
      _students = await _studentService.getAllStudentsForExport();
      _filteredStudents = List.from(_students);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoadingStudents(false);
    }
  }

  // Load receipts for selected student
  Future<void> loadReceipts() async {
    if (_selectedStudent == null) return;

    _setLoadingReceipts(true);
    try {
      _receipts =
          await _receiptService.getReceiptsByStudentId(_selectedStudent!.id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoadingReceipts(false);
    }
  }

  // Load receipt statistics
  Future<void> loadStatistics() async {
    try {
      _statistics = await _receiptService.getReceiptStatistics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Search students
  void searchStudents(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredStudents = List.from(_students);
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredStudents = _students
          .where(
            (student) =>
                student.name.toLowerCase().contains(lowerQuery) ||
                student.familyName.toLowerCase().contains(lowerQuery) ||
                student.email.toLowerCase().contains(lowerQuery) ||
                student.fullName.toLowerCase().contains(lowerQuery),
          )
          .toList();
    }
    notifyListeners();
  }

  // Select a student
  void selectStudent(Student student) {
    _selectedStudent = student;
    _receipts.clear();
    notifyListeners();
  }

  // Clear selected student
  void clearSelectedStudent() {
    _selectedStudent = null;
    _receipts.clear();
    notifyListeners();
  }

  // Upload receipt
  Future<bool> uploadReceipt({
    required String studentId,
    required dynamic file,
    required int concernsMonth,
    required int concernsYear,
  }) async {
    _setUploading(true);
    try {
      // Check if receipt already exists for this period
      final exists = await _receiptService.receiptExistsForPeriod(
        studentId: studentId,
        concernsMonth: concernsMonth,
        concernsYear: concernsYear,
      );

      if (exists) {
        _error = 'receipt_exists';
        _setUploading(false);
        return false;
      }

      await _receiptService.uploadReceipt(
        studentId: studentId,
        file: file,
        concernsMonth: concernsMonth,
        concernsYear: concernsYear,
      );

      // Reload receipts after successful upload
      await loadReceipts();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setUploading(false);
    }
  }

  // Delete receipt
  Future<bool> deleteReceipt(String receiptId) async {
    try {
      await _receiptService.deleteReceipt(receiptId);

      // Remove from local list
      _receipts.removeWhere((receipt) => receipt.id == receiptId);
      notifyListeners();

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Get receipt view URL
  Future<String?> getReceiptViewUrl(String filePath) async {
    try {
      return await _receiptService.createSignedUrl(filePath);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Check if receipt exists for period
  Future<bool> receiptExistsForPeriod({
    required String studentId,
    required int concernsMonth,
    required int concernsYear,
  }) async {
    try {
      return await _receiptService.receiptExistsForPeriod(
        studentId: studentId,
        concernsMonth: concernsMonth,
        concernsYear: concernsYear,
      );
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Private methods
  void _setLoadingStudents(bool loading) {
    _isLoadingStudents = loading;
    notifyListeners();
  }

  void _setLoadingReceipts(bool loading) {
    _isLoadingReceipts = loading;
    notifyListeners();
  }

  void _setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadStudents();
    if (_selectedStudent != null) {
      await loadReceipts();
    }
    await loadStatistics();
  }

  // Get month name helper
  String getMonthName(int month, {bool isGreek = false}) {
    if (month < 1 || month > 12) return '';

    const englishMonths = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    const greekMonths = [
      '',
      'Ιανουάριος',
      'Φεβρουάριος',
      'Μάρτιος',
      'Απρίλιος',
      'Μάιος',
      'Ιούνιος',
      'Ιούλιος',
      'Αύγουστος',
      'Σεπτέμβριος',
      'Οκτώβριος',
      'Νοέμβριος',
      'Δεκέμβριος',
    ];

    return isGreek ? greekMonths[month] : englishMonths[month];
  }
}
