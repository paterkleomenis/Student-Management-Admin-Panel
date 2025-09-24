import 'package:supabase_flutter/supabase_flutter.dart';

import '../db_client.dart';

class DocumentService {
  final SupabaseClient _client = DatabaseClient.client;

  // Get all document categories
  Future<List<Map<String, dynamic>>> getDocumentCategories() async {
    try {
      final response = await _client
          .from('document_categories')
          .select()
          .order('id', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch document categories: $e');
    }
  }

  // Get documents by student ID
  Future<List<Map<String, dynamic>>> getDocumentsByStudentId(
    String studentId,
  ) async {
    try {
      final response = await _client
          .from('student_documents')
          .select('''
            *,
            category:document_categories(*)
          ''')
          .eq('student_id', studentId)
          .order('uploaded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch student documents: $e');
    }
  }

  // Get all documents with filtering
  Future<List<Map<String, dynamic>>> getAllDocuments({
    int limit = 50,
    int offset = 0,
    String? uploadStatus,
    String? categoryKey,
    String? searchQuery,
  }) async {
    try {
      var query = _client.from('student_documents').select('''
        *,
        student:dormitory_students(id, name, family_name, email),
        category:document_categories(*)
      ''');

      // Apply filters
      if (uploadStatus != null && uploadStatus.isNotEmpty) {
        query = query.eq('upload_status', uploadStatus);
      }

      if (categoryKey != null && categoryKey.isNotEmpty) {
        query = query.eq('category.category_key', categoryKey);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'original_file_name.ilike.%$searchQuery%,'
          'student.name.ilike.%$searchQuery%,'
          'student.family_name.ilike.%$searchQuery%,'
          'student.email.ilike.%$searchQuery%',
        );
      }

      final response = await query
          .range(offset, offset + limit - 1)
          .order('uploaded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch documents: $e');
    }
  }

  // Get pending documents for review
  Future<List<Map<String, dynamic>>> getPendingDocuments({
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('student_documents')
          .select('''
            *,
            student:dormitory_students(id, name, family_name, email),
            category:document_categories(*)
          ''')
          .eq('upload_status', 'pending')
          .order('uploaded_at', ascending: true)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch pending documents: $e');
    }
  }

  // Get document by ID
  Future<Map<String, dynamic>?> getDocumentById(String documentId) async {
    try {
      final response = await _client.from('student_documents').select('''
            *,
            student:dormitory_students(id, name, family_name, email),
            category:document_categories(*)
          ''').eq('id', documentId).single();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Verify document
  Future<void> verifyDocument(String documentId, {String? notes}) async {
    try {
      final updateData = {
        'upload_status': 'verified',
        'verified_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('student_documents')
          .update(updateData)
          .eq('id', documentId);
    } catch (e) {
      throw Exception('Failed to verify document: $e');
    }
  }

  // Reject document
  Future<void> rejectDocument(String documentId, String reason) async {
    try {
      final updateData = {
        'upload_status': 'rejected',
        'rejection_reason': reason,
        'verified_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('student_documents')
          .update(updateData)
          .eq('id', documentId);
    } catch (e) {
      throw Exception('Failed to reject document: $e');
    }
  }

  // Reset document status to pending
  Future<void> resetDocumentStatus(String documentId) async {
    try {
      final updateData = {
        'upload_status': 'pending',
        'rejection_reason': null,
        'verified_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('student_documents')
          .update(updateData)
          .eq('id', documentId);
    } catch (e) {
      throw Exception('Failed to reset document status: $e');
    }
  }

  // Delete document
  Future<void> deleteDocument(
    String documentId,
  ) async {
    try {
      // First get the document to find the file path
      final document = await _client
          .from('student_documents')
          .select('file_path')
          .eq('id', documentId)
          .single();

      final filePath = document['file_path'] as String;

      // Delete from storage
      if (filePath.isNotEmpty) {
        try {
          await _client.storage.from('student-documents').remove([filePath]);
        } catch (e) {
          // Continue even if storage deletion fails
        }
      }

      // Delete record from database
      await _client.from('student_documents').delete().eq('id', documentId);
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  // Get document statistics
  Future<Map<String, dynamic>> getDocumentStatistics() async {
    try {
      // Get document categories
      final categoriesResponse = await _client
          .from('document_categories')
          .select('id, category_key, name_en, is_required');

      // Get document counts
      final documentsResponse = await _client
          .from('student_documents')
          .select('category_id, upload_status, uploaded_at');

      final categories = categoriesResponse as List;
      final documents = documentsResponse as List;

      final categoryStats = <String, Map<String, dynamic>>{};
      final statusCounts = <String, int>{
        'pending': 0,
        'verified': 0,
        'rejected': 0,
      };

      // Count by status
      for (final doc in documents) {
        final status = doc['upload_status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      // Count by category
      for (final category in categories) {
        final categoryId = category['id'] as int;
        final categoryKey = category['category_key'] as String;
        final categoryName = category['name_en'] as String;
        final isRequired = category['is_required'] as bool;

        final categoryDocs =
            documents.where((doc) => doc['category_id'] == categoryId);
        final totalUploads = categoryDocs.length;
        final pendingUploads = categoryDocs
            .where((doc) => doc['upload_status'] == 'pending')
            .length;
        final verifiedUploads = categoryDocs
            .where((doc) => doc['upload_status'] == 'verified')
            .length;
        final rejectedUploads = categoryDocs
            .where((doc) => doc['upload_status'] == 'rejected')
            .length;

        categoryStats[categoryKey] = {
          'name': categoryName,
          'isRequired': isRequired,
          'totalUploads': totalUploads,
          'pendingUploads': pendingUploads,
          'verifiedUploads': verifiedUploads,
          'rejectedUploads': rejectedUploads,
        };
      }

      // Documents by day (last 30 days)
      final now = DateTime.now();
      final dailyUploads = <String, int>{};
      for (var i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyUploads[dateKey] = 0;
      }

      for (final doc in documents) {
        final uploadedAt = DateTime.parse(doc['uploaded_at'] as String);
        final dateKey =
            '${uploadedAt.year}-${uploadedAt.month.toString().padLeft(2, '0')}-${uploadedAt.day.toString().padLeft(2, '0')}';
        if (dailyUploads.containsKey(dateKey)) {
          dailyUploads[dateKey] = (dailyUploads[dateKey] ?? 0) + 1;
        }
      }

      return {
        'totalDocuments': documents.length,
        'statusCounts': statusCounts,
        'categoryStats': categoryStats,
        'dailyUploads': dailyUploads,
      };
    } catch (e) {
      return {
        'totalDocuments': 0,
        'statusCounts': <String, int>{},
        'categoryStats': <String, Map<String, dynamic>>{},
        'dailyUploads': <String, int>{},
      };
    }
  }

  // Get document submissions by student
  Future<List<Map<String, dynamic>>> getDocumentSubmissions(
    String studentId,
  ) async {
    try {
      final response = await _client
          .from('document_submissions')
          .select()
          .eq('student_id', studentId)
          .order('submission_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Get total document count with filters
  Future<int> getTotalDocumentCount({
    String? uploadStatus,
    String? categoryKey,
    String? searchQuery,
  }) async {
    try {
      var query = _client.from('student_documents').select('id');

      // Apply same filters as getAllDocuments
      if (uploadStatus != null && uploadStatus.isNotEmpty) {
        query = query.eq('upload_status', uploadStatus);
      }

      if (categoryKey != null && categoryKey.isNotEmpty) {
        query = query.eq('category.category_key', categoryKey);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'original_file_name.ilike.%$searchQuery%,'
          'student.name.ilike.%$searchQuery%,'
          'student.family_name.ilike.%$searchQuery%,'
          'student.email.ilike.%$searchQuery%',
        );
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Get file URL for viewing
  Future<String?> getDocumentUrl(String filePath) async {
    try {
      final url =
          _client.storage.from('student-documents').getPublicUrl(filePath);
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
          .from('student-documents')
          .createSignedUrl(filePath, expiresIn);
      return url;
    } catch (e) {
      return null;
    }
  }

  // Bulk operations
  Future<void> bulkVerifyDocuments(List<String> documentIds) async {
    try {
      final updateData = {
        'upload_status': 'verified',
        'verified_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('student_documents')
          .update(updateData)
          .inFilter('id', documentIds);
    } catch (e) {
      throw Exception('Failed to bulk verify documents: $e');
    }
  }

  Future<void> bulkRejectDocuments(
    List<String> documentIds,
    String reason,
  ) async {
    try {
      final updateData = {
        'upload_status': 'rejected',
        'rejection_reason': reason,
        'verified_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('student_documents')
          .update(updateData)
          .inFilter('id', documentIds);
    } catch (e) {
      throw Exception('Failed to bulk reject documents: $e');
    }
  }
}
