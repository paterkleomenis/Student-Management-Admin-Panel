import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/student.dart';
import '../services/language_service.dart';
import '../services/student_service.dart';
import '../utils/desktop_constants.dart';

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key, this.studentId});
  final String? studentId;

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final StudentService _studentService = StudentService();
  Student? _student;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    if (widget.studentId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final student = await _studentService.getStudentById(widget.studentId!);
      setState(() {
        _student = student;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading student data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteStudent() async {
    if (_student == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
          'Are you sure you want to delete ${_student!.fullName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await _studentService.deleteStudent(_student!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete student'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<LanguageService>(
        builder: (context, langService, child) => Scaffold(
          appBar: AppBar(
            title: Text(langService.getString('students.student_details')),
            actions: [
              if (_student != null && !_isDeleting) ...[
                IconButton(
                  onPressed: () => context.go('/students/edit/${_student!.id}'),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Student',
                ),
                IconButton(
                  onPressed: _deleteStudent,
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete Student',
                ),
              ],
              if (_isDeleting)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _student == null
                  ? _buildNotFound(langService)
                  : _buildStudentDetails(langService),
        ),
      );

  Widget _buildNotFound(LanguageService langService) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Student Not Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'The requested student could not be found.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );

  Widget _buildStudentDetails(LanguageService langService) =>
      SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
        child: Column(
          children: [
            _buildStudentHeader(),
            const SizedBox(height: 24),
            if (ResponsiveUtils.isDesktop(context))
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildPersonalInfo()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildEducationInfo()),
                ],
              )
            else ...[
              _buildPersonalInfo(),
              const SizedBox(height: 16),
              _buildEducationInfo(),
            ],
            const SizedBox(height: 16),
            _buildContactInfo(),
            const SizedBox(height: 16),
            _buildParentInfo(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      );

  Widget _buildStudentHeader() => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  '${_student!.name[0]}${_student!.familyName[0]}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _student!.fullName,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_student!.university} • ${_student!.department}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Student ID: ${_student!.id}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _student!.yearOfStudy ?? '',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_student!.hasOtherDegree) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Has Other Degree',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPersonalInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Full Name', _student!.fullName, Icons.person),
              _buildInfoRow(
                  'Father Name', _student!.fatherName ?? '', Icons.person),
              _buildInfoRow(
                  'Mother Name', _student!.motherName ?? '', Icons.person),
              _buildInfoRow(
                'Birth Date',
                '${_student!.birthDate.day}/${_student!.birthDate.month}/${_student!.birthDate.year}',
                Icons.cake,
              ),
              _buildInfoRow(
                'Birth Place',
                _student!.birthPlace ?? '',
                Icons.location_on,
              ),
              _buildInfoRow(
                  'ID Card', _student!.idCardNumber, Icons.credit_card),
              _buildInfoRow(
                'Issuing Authority',
                _student!.issuingAuthority ?? '',
                Icons.account_balance,
              ),
              if (_student!.taxNumber?.isNotEmpty == true)
                _buildInfoRow(
                    'Tax Number', _student!.taxNumber ?? '', Icons.receipt),
            ],
          ),
        ),
      );

  Widget _buildEducationInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Education Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                'University',
                _student!.university ?? '',
                Icons.account_balance,
              ),
              _buildInfoRow(
                  'Department', _student!.department ?? '', Icons.category),
              _buildInfoRow(
                  'Year of Study', _student!.yearOfStudy ?? '', Icons.school),
              _buildInfoRow(
                'Has Other Degree',
                _student!.hasOtherDegree ? 'Yes' : 'No',
                Icons.emoji_events,
              ),
              _buildInfoRow(
                'Registration Date',
                '${_student!.createdAt.day}/${_student!.createdAt.month}/${_student!.createdAt.year}',
                Icons.event,
              ),
            ],
          ),
        ),
      );

  Widget _buildContactInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Email', _student!.email, Icons.email),
              _buildInfoRow('Phone', _student!.phone ?? '', Icons.phone),
            ],
          ),
        ),
      );

  Widget _buildParentInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parent Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              if (_student!.fatherJob?.isNotEmpty == true)
                _buildInfoRow(
                    'Father Job', _student!.fatherJob ?? '', Icons.work),
              if (_student!.motherJob?.isNotEmpty == true)
                _buildInfoRow(
                    'Mother Job', _student!.motherJob ?? '', Icons.work),
              if (_student!.parentAddress?.isNotEmpty == true)
                _buildInfoRow(
                    'Address', _student!.fullParentAddress, Icons.home),
            ],
          ),
        ),
      );

  Widget _buildInfoRow(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? 'Not provided' : value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: value.isEmpty ? Colors.grey[400] : null,
                          fontStyle: value.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildActionButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => context.go('/students/edit/${_student!.id}'),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Student'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _isDeleting ? null : _deleteStudent,
            icon: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete),
            label: const Text('Delete Student'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      );
}
