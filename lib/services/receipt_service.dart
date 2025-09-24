import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db_client.dart';
import '../models/student_receipt.dart';

class ReceiptService {
  final SupabaseClient _client = DatabaseClient.client;

  // Get all receipts with filtering
  Future<List<Map<String, dynamic>>> getAllReceipts({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    int? concernsMonth,
    int? concernsYear,
  }) async {
    try {
      var query = _client.from('student_receipts').select('''
        *,
        student:dormitory_students(id, name, family_name, email)
      ''');

      // Apply filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'original_file_name.ilike.%$searchQuery%,'
          'student.name.ilike.%$searchQuery%,'
          'student.family_name.ilike.%$searchQuery%,'
          'student.email.ilike.%$searchQuery%',
        );
      }

      if (concernsMonth != null) {
        query = query.eq('concerns_month', concernsMonth);
      }

      if (concernsYear != null) {
        query = query.eq('concerns_year', concernsYear);
      }

      final response = await query
          .range(offset, offset + limit - 1)
          .order('uploaded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch receipts: $e');
    }
  }

  // Get receipts by student ID
  Future<List<StudentReceipt>> getReceiptsByStudentId(
    String studentId,
  ) async {
    try {
      final response = await _client
          .from('student_receipts')
          .select()
          .eq('student_id', studentId)
          .order('uploaded_at', ascending: false);

      return (response as List)
          .map((json) => StudentReceipt.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch student receipts: $e');
    }
  }

  // Get receipt by ID
  Future<Map<String, dynamic>?> getReceiptById(String receiptId) async {
    try {
      final response = await _client.from('student_receipts').select('''
            *,
            student:dormitory_students(id, name, family_name, email)
          ''').eq('id', receiptId).single();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Upload receipt
  Future<StudentReceipt> uploadReceipt({
    required String studentId,
    required PlatformFile file,
    required int concernsMonth,
    required int concernsYear,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.extension ?? '';
      final fileName =
          'receipt_${timestamp}_${concernsMonth}_$concernsYear.$extension';
      final filePath = 'receipts/$studentId/$fileName';

      // Upload file to storage
      Uint8List? fileBytes;
      if (file.bytes != null) {
        fileBytes = file.bytes;
      } else if (file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      } else {
        throw Exception('No file data available');
      }

      await _client.storage
          .from('student-receipts')
          .uploadBinary(filePath, fileBytes!);

      // Create receipt record in database
      final receiptData = {
        'student_id': studentId,
        'file_name': fileName,
        'original_file_name': file.name,
        'file_path': filePath,
        'file_size_bytes': file.size,
        'file_type': extension,
        'mime_type': _getMimeType(extension),
        'concerns_month': concernsMonth,
        'concerns_year': concernsYear,
        'metadata': {
          'original_name': file.name,
          'upload_timestamp': timestamp,
        },
      };

      final response = await _client
          .from('student_receipts')
          .insert(receiptData)
          .select()
          .single();

      return StudentReceipt.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upload receipt: $e');
    }
  }

  // Delete receipt
  Future<void> deleteReceipt(String receiptId) async {
    try {
      // First get the receipt to find the file path
      final receipt = await _client
          .from('student_receipts')
          .select('file_path')
          .eq('id', receiptId)
          .single();

      final filePath = receipt['file_path'] as String;

      // Delete from storage
      if (filePath.isNotEmpty) {
        try {
          await _client.storage.from('student-receipts').remove([filePath]);
        } catch (e) {
          // Continue even if storage deletion fails
        }
      }

      // Delete record from database
      await _client.from('student_receipts').delete().eq('id', receiptId);
    } catch (e) {
      throw Exception('Failed to delete receipt: $e');
    }
  }

  // Get receipt statistics
  Future<Map<String, dynamic>> getReceiptStatistics() async {
    try {
      final response = await _client.from('student_receipts').select(
            'concerns_month, concerns_year, uploaded_at, file_size_bytes',
          );

      final receipts = response as List;

      // Count by month
      final monthlyCounts = <int, int>{};
      for (var i = 1; i <= 12; i++) {
        monthlyCounts[i] = 0;
      }

      // Count by year
      final yearlyCounts = <int, int>{};

      // Total size and count
      var totalSize = 0;
      final totalCount = receipts.length;

      for (final receipt in receipts) {
        final month = receipt['concerns_month'] as int?;
        final year = receipt['concerns_year'] as int?;
        final size = (receipt['file_size_bytes'] as num?)?.toInt() ?? 0;

        if (month != null && month >= 1 && month <= 12) {
          monthlyCounts[month] = (monthlyCounts[month] ?? 0) + 1;
        }

        if (year != null) {
          yearlyCounts[year] = (yearlyCounts[year] ?? 0) + 1;
        }

        totalSize += size;
      }

      // Receipts by day (last 30 days)
      final now = DateTime.now();
      final dailyUploads = <String, int>{};
      for (var i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyUploads[dateKey] = 0;
      }

      for (final receipt in receipts) {
        final uploadedAt = receipt['uploaded_at'] as String?;
        if (uploadedAt != null) {
          final date = DateTime.tryParse(uploadedAt);
          if (date != null) {
            final dateKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            if (dailyUploads.containsKey(dateKey)) {
              dailyUploads[dateKey] = (dailyUploads[dateKey] ?? 0) + 1;
            }
          }
        }
      }

      return {
        'totalReceipts': totalCount,
        'totalSize': totalSize,
        'monthlyCounts': monthlyCounts,
        'yearlyCounts': yearlyCounts,
        'dailyUploads': dailyUploads,
        'averageSize': totalCount > 0 ? totalSize / totalCount : 0,
      };
    } catch (e) {
      return {
        'totalReceipts': 0,
        'totalSize': 0,
        'monthlyCounts': <int, int>{},
        'yearlyCounts': <int, int>{},
        'dailyUploads': <String, int>{},
        'averageSize': 0,
      };
    }
  }

  // Get total receipt count with filters
  Future<int> getTotalReceiptCount({
    String? searchQuery,
    int? concernsMonth,
    int? concernsYear,
  }) async {
    try {
      var query = _client.from('student_receipts').select('id');

      // Apply same filters as getAllReceipts
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'original_file_name.ilike.%$searchQuery%,'
          'student.name.ilike.%$searchQuery%,'
          'student.family_name.ilike.%$searchQuery%,'
          'student.email.ilike.%$searchQuery%',
        );
      }

      if (concernsMonth != null) {
        query = query.eq('concerns_month', concernsMonth);
      }

      if (concernsYear != null) {
        query = query.eq('concerns_year', concernsYear);
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Get file URL for viewing
  Future<String?> getReceiptUrl(String filePath) async {
    try {
      final url =
          _client.storage.from('student-receipts').getPublicUrl(filePath);
      return url;
    } catch (e) {
      return null;
    }
  }

  // Create signed URL for temporary access
  Future<String?> createSignedUrl(
    String filePath, {
    int expiresIn = 3600,
  }) async {
    try {
      final url = await _client.storage
          .from('student-receipts')
          .createSignedUrl(filePath, expiresIn);
      return url;
    } catch (e) {
      return null;
    }
  }

  // Check if receipt exists for student and period
  Future<bool> receiptExistsForPeriod({
    required String studentId,
    required int concernsMonth,
    required int concernsYear,
  }) async {
    try {
      final response = await _client
          .from('student_receipts')
          .select('id')
          .eq('student_id', studentId)
          .eq('concerns_month', concernsMonth)
          .eq('concerns_year', concernsYear);

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get receipts for a specific period
  Future<List<Map<String, dynamic>>> getReceiptsForPeriod({
    required int concernsMonth,
    required int concernsYear,
  }) async {
    try {
      final response = await _client
          .from('student_receipts')
          .select('''
        *,
        student:dormitory_students(id, name, family_name, email)
      ''')
          .eq('concerns_month', concernsMonth)
          .eq('concerns_year', concernsYear)
          .order('uploaded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch receipts for period: $e');
    }
  }

  // Bulk operations
  Future<void> bulkDeleteReceipts(List<String> receiptIds) async {
    try {
      // First get all the file paths
      final receipts = await _client
          .from('student_receipts')
          .select('file_path')
          .inFilter('id', receiptIds);

      final filePaths = (receipts as List)
          .map((r) => r['file_path'] as String)
          .where((path) => path.isNotEmpty)
          .toList();

      // Delete from storage
      if (filePaths.isNotEmpty) {
        try {
          await _client.storage.from('student-receipts').remove(filePaths);
        } catch (e) {
          // Continue even if storage deletion fails
        }
      }

      // Delete records from database
      await _client
          .from('student_receipts')
          .delete()
          .inFilter('id', receiptIds);
    } catch (e) {
      throw Exception('Failed to bulk delete receipts: $e');
    }
  }

  // Helper method to determine MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
