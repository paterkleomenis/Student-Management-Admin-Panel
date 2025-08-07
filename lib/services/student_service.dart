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
      var query = _client.from('students').select();

      // Apply server-side filtering
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'name.ilike.%$searchQuery%,'
          'family_name.ilike.%$searchQuery%,'
          'email.ilike.%$searchQuery%,'
          'phone.ilike.%$searchQuery%',
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

      return (response as List).map((json) => Student.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch students: $e');
    }
  }

  // Get all students for export (no pagination)
  Future<List<Student>> getAllStudentsForExport() async {
    try {
      final response = await _client
          .from('students')
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
      final response =
          await _client.from('students').select().eq('id', id).single();

      return Student.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Create new student
  Future<Student> createStudent(Student student) async {
    try {
      final response = await _client
          .from('students')
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
      Map<String, dynamic> studentData,) async {
    try {
      final response =
          await _client.from('students').insert(studentData).select().single();

      return Student.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  // Update student
  Future<Student> updateStudent(Student student) async {
    try {
      final response = await _client
          .from('students')
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
      await _client.from('students').delete().eq('id', id);
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
      var query = _client.from('students').select('id');

      // Apply same filters as getStudents
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'name.ilike.%$searchQuery%,'
          'family_name.ilike.%$searchQuery%,'
          'email.ilike.%$searchQuery%,'
          'phone.ilike.%$searchQuery%',
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
          .from('students')
          .select('university')
          .order('university');

      final universities = (response as List)
          .map((row) => row['university'] as String)
          .where((university) => university.isNotEmpty)
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
          .from('students')
          .select('department')
          .order('department');

      final departments = (response as List)
          .map((row) => row['department'] as String)
          .where((department) => department.isNotEmpty)
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
          .from('students')
          .select('year_of_study')
          .order('year_of_study');

      final years = (response as List)
          .map((row) => row['year_of_study'] as String)
          .where((year) => year.isNotEmpty)
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
          .from('students')
          .select('university, department, year_of_study');

      final data = response as List;
      final totalCount = data.length;

      // Count by university
      final universityCounts = <String, int>{};
      for (final row in data) {
        final university = row['university'] as String? ?? 'Unknown';
        if (university.isNotEmpty) {
          universityCounts[university] =
              (universityCounts[university] ?? 0) + 1;
        }
      }

      // Count by department
      final departmentCounts = <String, int>{};
      for (final row in data) {
        final department = row['department'] as String? ?? 'Unknown';
        if (department.isNotEmpty) {
          departmentCounts[department] =
              (departmentCounts[department] ?? 0) + 1;
        }
      }

      // Count by year of study
      final yearCounts = <String, int>{};
      for (final row in data) {
        final year = row['year_of_study'] as String? ?? 'Unknown';
        if (year.isNotEmpty) {
          yearCounts[year] = (yearCounts[year] ?? 0) + 1;
        }
      }

      return {
        'totalStudents': totalCount,
        'universityCounts': universityCounts,
        'departmentCounts': departmentCounts,
        'yearCounts': yearCounts,
      };
    } catch (e) {
      return {
        'totalStudents': 0,
        'universityCounts': <String, int>{},
        'departmentCounts': <String, int>{},
        'yearCounts': <String, int>{},
      };
    }
  }
}
