import 'package:supabase_flutter/supabase_flutter.dart';

import '../db_client.dart';
import '../models/student.dart';

class StudentService {
  final SupabaseClient _client = DatabaseClient.client;

  // Get all students with pagination and server-side filtering
  Future<List<Student>> getStudents({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    String? university,
    String? department,
    String? yearOfStudy,
    String? applicationStatus,
  }) async {
    try {
      var query = _client.from('dormitory_students').select();

      // Apply server-side filtering
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'name.ilike.%$searchQuery%,'
          'family_name.ilike.%$searchQuery%,'
          'email.ilike.%$searchQuery%,'
          'phone.ilike.%$searchQuery%,'
          'id_card_number.ilike.%$searchQuery%',
        );
      }

      if (university != null && university.isNotEmpty) {
        query = query.eq('university', university);
      }

      if (department != null && department.isNotEmpty) {
        query = query.eq('department', department);
      }

      if (yearOfStudy != null && yearOfStudy.isNotEmpty) {
        query = query.eq('year_of_study', yearOfStudy);
      }

      if (applicationStatus != null && applicationStatus.isNotEmpty) {
        query = query.eq('application_status', applicationStatus);
      }

      final response = await query
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Student.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch students: $e');
    }
  }

  // Get all students for export (no pagination)
  Future<List<Student>> getAllStudentsForExport() async {
    try {
      final response = await _client
          .from('dormitory_students')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((json) => Student.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all students: $e');
    }
  }

  // Get student by ID
  Future<Student?> getStudentById(String id) async {
    try {
      final response = await _client
          .from('dormitory_students')
          .select()
          .eq('id', id)
          .single();

      return Student.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Get student with documents
  Future<Map<String, dynamic>?> getStudentWithDocuments(String id) async {
    try {
      // Get student data
      final studentResponse = await _client
          .from('dormitory_students')
          .select()
          .eq('id', id)
          .single();

      final student = Student.fromJson(studentResponse);

      // Get student documents
      final documentsResponse =
          await _client.from('student_documents').select('''
            *,
            category:document_categories(*)
          ''').eq('student_id', id).order('uploaded_at', ascending: false);

      // Get document submissions
      final submissionsResponse = await _client
          .from('document_submissions')
          .select()
          .eq('student_id', id)
          .order('submission_date', ascending: false);

      return {
        'student': student,
        'documents': documentsResponse,
        'submissions': submissionsResponse,
      };
    } catch (e) {
      return null;
    }
  }

  // Create new student
  Future<Student> createStudent(Student student) async {
    try {
      final response = await _client
          .from('dormitory_students')
          .insert(student.toJson())
          .select()
          .single();

      return Student.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  // Create new student from data (without ID, let database generate it)
  Future<Student> createStudentFromData(
      Map<String, dynamic> studentData) async {
    try {
      final response = await _client
          .from('dormitory_students')
          .insert(studentData)
          .select()
          .single();

      return Student.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  // Update student
  Future<Student> updateStudent(Student student) async {
    try {
      final response = await _client
          .from('dormitory_students')
          .update(student.toJson())
          .eq('id', student.id ?? "")
          .select()
          .single();

      return Student.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  // Update student application status

  // Delete student
  Future<void> deleteStudent(String id) async {
    try {
      await _client.from('dormitory_students').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }

  // Get total count of students with filtering
  Future<int> getTotalStudentsCount({
    String? searchQuery,
    String? university,
    String? department,
    String? yearOfStudy,
    String? applicationStatus,
  }) async {
    try {
      var query = _client.from('dormitory_students').select('id');

      // Apply same filters as getStudents
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'name.ilike.%$searchQuery%,'
          'family_name.ilike.%$searchQuery%,'
          'email.ilike.%$searchQuery%,'
          'phone.ilike.%$searchQuery%,'
          'id_card_number.ilike.%$searchQuery%',
        );
      }

      if (university != null && university.isNotEmpty) {
        query = query.eq('university', university);
      }

      if (department != null && department.isNotEmpty) {
        query = query.eq('department', department);
      }

      if (yearOfStudy != null && yearOfStudy.isNotEmpty) {
        query = query.eq('year_of_study', yearOfStudy);
      }

      if (applicationStatus != null && applicationStatus.isNotEmpty) {
        query = query.eq('application_status', applicationStatus);
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Get unique universities
  Future<List<String>> getUniversities() async {
    try {
      final response = await _client
          .from('dormitory_students')
          .select('university')
          .order('university');

      final universities = (response as List)
          .map((row) => row['university'] as String?)
          .where((university) => university != null && university.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      return universities;
    } catch (e) {
      return [];
    }
  }

  // Get unique departments
  Future<List<String>> getDepartments() async {
    try {
      final response = await _client
          .from('dormitory_students')
          .select('department')
          .order('department');

      final departments = (response as List)
          .map((row) => row['department'] as String?)
          .where((department) => department != null && department.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      return departments;
    } catch (e) {
      return [];
    }
  }

  // Get unique years of study
  Future<List<String>> getYearsOfStudy() async {
    try {
      final response = await _client
          .from('dormitory_students')
          .select('year_of_study')
          .order('year_of_study');

      final years = (response as List)
          .map((row) => row['year_of_study']?.toString())
          .where((year) => year != null && year.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      return years;
    } catch (e) {
      return [];
    }
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      // Get all data in one efficient query
      final response = await _client
          .from('dormitory_students')
          .select('university, department, year_of_study, created_at');

      final data = response as List;
      final totalCount = data.length;

      // Count by university
      final universityCounts = <String, int>{};
      for (final row in data) {
        final university = row['university'] as String? ?? 'Unknown';
        if (university.isNotEmpty && university != 'Unknown') {
          universityCounts[university] =
              (universityCounts[university] ?? 0) + 1;
        }
      }

      // Count by department
      final departmentCounts = <String, int>{};
      for (final row in data) {
        final department = row['department'] as String? ?? 'Unknown';
        if (department.isNotEmpty && department != 'Unknown') {
          departmentCounts[department] =
              (departmentCounts[department] ?? 0) + 1;
        }
      }

      // Count by year of study
      final yearCounts = <String, int>{};
      for (final row in data) {
        final year = row['year_of_study']?.toString() ?? 'Unknown';
        if (year.isNotEmpty && year != 'Unknown') {
          yearCounts[year] = (yearCounts[year] ?? 0) + 1;
        }
      }

      // Applications by month (last 12 months)
      final now = DateTime.now();
      final monthlyApplications = <String, int>{};
      for (int i = 11; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey =
            '${month.year}-${month.month.toString().padLeft(2, '0')}';
        monthlyApplications[monthKey] = 0;
      }

      for (final row in data) {
        final createdAt = DateTime.parse(row['created_at'] as String);
        final monthKey =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
        if (monthlyApplications.containsKey(monthKey)) {
          monthlyApplications[monthKey] =
              (monthlyApplications[monthKey] ?? 0) + 1;
        }
      }

      return {
        'totalStudents': totalCount,
        'universityCounts': universityCounts,
        'departmentCounts': departmentCounts,
        'yearCounts': yearCounts,
        'monthlyApplications': monthlyApplications,
      };
    } catch (e) {
      return {
        'totalStudents': 0,
        'universityCounts': <String, int>{},
        'departmentCounts': <String, int>{},
        'yearCounts': <String, int>{},
        'monthlyApplications': <String, int>{},
      };
    }
  }

  // Get students with incomplete required documents
  Future<List<Map<String, dynamic>>> getIncompleteApplications() async {
    try {
      // Get required categories
      final requiredCategoriesResponse = await _client
          .from('document_categories')
          .select('id, category_key, name_en')
          .eq('is_required', true);

      final requiredCategories = requiredCategoriesResponse as List;
      final requiredCategoryIds =
          requiredCategories.map((cat) => cat['id'] as int).toList();

      // Get all students with submitted status
      final studentsResponse = await _client
          .from('dormitory_students')
          .select('id, name, family_name, email, application_status')
          .eq('application_status', 'submitted');

      final students = studentsResponse as List;
      final incompleteStudents = <Map<String, dynamic>>[];

      for (final student in students) {
        final studentId = student['id'] as String;

        // Get student's uploaded documents
        final documentsResponse = await _client
            .from('student_documents')
            .select('category_id')
            .eq('student_id', studentId);

        final uploadedCategoryIds = (documentsResponse as List)
            .map((doc) => doc['category_id'] as int)
            .toSet();

        // Check for missing required documents
        final missingCategories = requiredCategoryIds
            .where((catId) => !uploadedCategoryIds.contains(catId))
            .toList();

        if (missingCategories.isNotEmpty) {
          final missingCategoryNames = requiredCategories
              .where((cat) => missingCategories.contains(cat['id']))
              .map((cat) => cat['name_en'] as String)
              .toList();

          incompleteStudents.add({
            ...student,
            'missingDocuments': missingCategoryNames,
            'missingCount': missingCategories.length,
          });
        }
      }

      return incompleteStudents;
    } catch (e) {
      return [];
    }
  }
}
