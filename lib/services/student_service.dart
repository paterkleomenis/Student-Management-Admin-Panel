import 'dart:convert';

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

      final response = await query
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      try {
        return (response as List).map((json) {
          try {
            return Student.fromJson(json);
          } catch (parseError) {
            // Error parsing student data
            rethrow;
          }
        }).toList();
      } catch (mappingError) {
        // Error mapping student list
        rethrow;
      }
    } catch (e) {
      // Error in getStudents
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

      try {
        return (response as List).map((json) {
          try {
            return Student.fromJson(json);
          } catch (parseError) {
            // Error parsing student data in getAllStudentsForExport
            rethrow;
          }
        }).toList();
      } catch (mappingError) {
        // Error mapping student list in getAllStudentsForExport
        rethrow;
      }
    } catch (e) {
      // Error in getAllStudentsForExport
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

      try {
        return Student.fromJson(response);
      } catch (parseError) {
        // Error parsing student data in getStudentById
        return null;
      }
    } catch (e) {
      // Error in getStudentById
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
      // First create a user in auth.users table
      final authResponse = await _client.auth.admin.createUser(
        AdminUserAttributes(
          email: student.email,
          emailConfirm: true,
          userMetadata: {
            'name': student.name,
            'family_name': student.familyName,
            'role': 'student',
          },
        ),
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create auth user');
      }

      // Use the auth user ID as the student ID
      final studentData = student.toJson();
      studentData['id'] = authResponse.user!.id;

      try {
        final response = await _client
            .from('dormitory_students')
            .insert(studentData)
            .select()
            .single();

        return Student.fromJson(response);
      } catch (studentError) {
        // If student creation fails, clean up the auth user
        try {
          await _client.auth.admin.deleteUser(authResponse.user!.id);
        } catch (cleanupError) {
          // Log cleanup error but throw original error
        }
        throw Exception('Failed to create student: $studentError');
      }
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  // Create new student from data (with auth user integration)
  Future<Student> createStudentFromData(
    Map<String, dynamic> studentData,
  ) async {
    // Store admin session data before any auth operations
    final adminSession = _client.auth.currentSession;
    final adminUserId = adminSession?.user.id;

    // Get the actual session data and stringify it
    String? sessionBackup;
    if (adminSession != null) {
      sessionBackup = jsonEncode(adminSession.toJson());
    }

    try {
      // First create a user in auth.users table using regular sign up
      final authResponse = await _client.auth.signUp(
        email: studentData['email'] as String,
        password: studentData['password'] as String,
        data: {
          'full_name': '${studentData['name']} ${studentData['family_name']}',
        },
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create auth user');
      }

      // Use the auth user ID as the student ID
      studentData['id'] = authResponse.user!.id;

      // Remove password before database insertion (it's only for auth)
      studentData.remove('password');

      try {
        final response = await _client
            .from('dormitory_students')
            .insert(studentData)
            .select()
            .single();

        return Student.fromJson(response);
      } catch (studentError) {
        // If student creation fails, clean up the auth user
        try {
          await _client.auth.admin.deleteUser(authResponse.user!.id);
        } catch (cleanupError) {
          // Log cleanup error but throw original error
        }
        throw Exception('Failed to create student: $studentError');
      }
    } catch (e) {
      throw Exception('Failed to create student: $e');
    } finally {
      // Check if admin got logged out and restore session if needed
      final currentUser = _client.auth.currentUser;
      final currentUserId = currentUser?.id;

      // If no user or different user, admin was logged out - restore session
      if (sessionBackup != null &&
          (currentUserId == null || currentUserId != adminUserId)) {
        try {
          // Restore the admin session using the session backup
          await _client.auth.recoverSession(sessionBackup);
        } catch (restoreError) {
          // If restore fails completely, admin will need to re-login
          // Session restore failed silently
        }
      }
    }
  }

  // Update student
  Future<Student> updateStudent(Student student) async {
    try {
      final response = await _client
          .from('dormitory_students')
          .update(student.toJson())
          .eq('id', student.id)
          .select()
          .single();

      return Student.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  // Delete student
  Future<void> deleteStudent(String id) async {
    try {
      // Delete the student record (this will also delete the auth user due to CASCADE)
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
      for (var i = 11; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i);
        final monthKey =
            '${month.year}-${month.month.toString().padLeft(2, '0')}';
        monthlyApplications[monthKey] = 0;
      }

      for (final row in data) {
        final createdAtStr = row['created_at'] as String?;
        if (createdAtStr != null) {
          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt != null) {
            final monthKey =
                '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
            if (monthlyApplications.containsKey(monthKey)) {
              monthlyApplications[monthKey] =
                  (monthlyApplications[monthKey] ?? 0) + 1;
            }
          }
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
}
