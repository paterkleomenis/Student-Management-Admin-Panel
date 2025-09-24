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
          SnackBar(
            content: Text(
              Provider.of<LanguageService>(context, listen: false)
                  .getString('student_detail.error_loading'),
            ),
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
      builder: (context) => Consumer<LanguageService>(
        builder: (context, langService, child) => AlertDialog(
          title: Text(langService.getString('student_detail.delete_title')),
          content: Text(
            langService.getString(
              'student_detail.delete_message',
              params: {'name': _student!.fullName},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(langService.getString('common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(langService.getString('common.delete')),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await _studentService.deleteStudent(_student!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LanguageService>(context, listen: false)
                  .getString('student_detail.delete_success'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LanguageService>(context, listen: false)
                  .getString('student_detail.delete_failed'),
            ),
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
                Consumer<LanguageService>(
                  builder: (context, langService, child) => IconButton(
                    onPressed: () =>
                        context.go('/students/edit/${_student!.id}'),
                    icon: const Icon(Icons.edit),
                    tooltip:
                        langService.getString('student_detail.edit_tooltip'),
                  ),
                ),
                Consumer<LanguageService>(
                  builder: (context, langService, child) => IconButton(
                    onPressed: _deleteStudent,
                    icon: const Icon(Icons.delete),
                    tooltip:
                        langService.getString('student_detail.delete_tooltip'),
                  ),
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
            Consumer<LanguageService>(
              builder: (context, langService, child) => Text(
                langService.getString('student_detail.student_not_found'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The requested student could not be found.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Consumer<LanguageService>(
              builder: (context, langService, child) => ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(langService.getString('common.go_back')),
              ),
            ),
          ],
        ),
      );

  Widget _buildStudentDetails(LanguageService langService) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return SingleChildScrollView(
      padding: ResponsiveUtils.getResponsiveContentPadding(context),
      child: Column(
        children: [
          _buildStudentHeader(),
          SizedBox(
            height: ResponsiveUtils.getResponsiveVerticalSpacing(context),
          ),
          if (isMobile)
            Column(
              children: [
                _buildPersonalInfo(),
                SizedBox(
                    height:
                        ResponsiveUtils.getResponsiveVerticalSpacing(context),),
                _buildEducationInfo(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildPersonalInfo()),
                SizedBox(
                  width:
                      ResponsiveUtils.getResponsiveHorizontalSpacing(context),
                ),
                Expanded(
                  flex: 2,
                  child: _buildEducationInfo(),
                ),
              ],
            ),
          SizedBox(
            height: ResponsiveUtils.getResponsiveVerticalSpacing(context),
          ),
          _buildContactInfo(),
          SizedBox(
            height: ResponsiveUtils.getResponsiveVerticalSpacing(context),
          ),
          _buildParentInfo(),
          SizedBox(
            height: ResponsiveUtils.getResponsiveVerticalSpacing(context),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStudentHeader() {
    final isMobile = ResponsiveUtils.isMobile(context);
    final cardPadding = ResponsiveUtils.getResponsiveCardPadding(context);

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                '${_student!.name[0]}${_student!.familyName[0]}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context, ResponsiveUtils.isMobile(context) ? 20 : 24,),
                  fontWeight: FontWeight.bold,
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                          child: Consumer<LanguageService>(
                            builder: (context, langService, child) => Text(
                              langService.getString(
                                'student_detail.has_other_degree',
                              ),
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
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
  }

  Widget _buildPersonalInfo() => Card(
        child: Padding(
          padding:
              EdgeInsets.all(ResponsiveUtils.getResponsiveCardPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<LanguageService>(
                builder: (context, langService, child) => Text(
                  langService.getString('student_detail.personal_info'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<LanguageService>(
                builder: (context, langService, child) => Column(
                  children: [
                    _buildInfoRow(
                      langService.getString('student_detail.full_name'),
                      _student!.fullName,
                      Icons.person,
                    ),
                    _buildInfoRow(
                      langService.getString('student_detail.father_name'),
                      _student!.fatherName ?? '',
                      Icons.person,
                    ),
                    _buildInfoRow(
                      langService.getString('student_detail.mother_name'),
                      _student!.motherName ?? '',
                      Icons.person,
                    ),
                  ],
                ),
              ),
              Consumer<LanguageService>(
                builder: (context, langService, child) => Column(
                  children: [
                    _buildInfoRow(
                      langService.getString('student_detail.birth_date'),
                      _student!.birthDate != null
                          ? '${_student!.birthDate!.day}/${_student!.birthDate!.month}/${_student!.birthDate!.year}'
                          : langService.getString('common.not_provided'),
                      Icons.cake,
                    ),
                    _buildInfoRow(
                      langService.getString('student_detail.birth_place'),
                      _student!.birthPlace,
                      Icons.location_on,
                    ),
                    _buildInfoRow(
                      langService.getString('student_detail.id_card'),
                      _student!.idCardNumber ?? '',
                      Icons.credit_card,
                    ),
                    _buildInfoRow(
                      langService.getString('student_detail.issuing_authority'),
                      _student!.issuingAuthority ?? '',
                      Icons.account_balance,
                    ),
                  ],
                ),
              ),
              if (_student!.taxNumber?.isNotEmpty ?? false)
                Consumer<LanguageService>(
                  builder: (context, langService, child) => _buildInfoRow(
                    langService.getString('student_detail.tax_number'),
                    _student!.taxNumber ?? '',
                    Icons.receipt,
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildEducationInfo() => Card(
        child: Padding(
          padding:
              EdgeInsets.all(ResponsiveUtils.getResponsiveCardPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<LanguageService>(
                builder: (context, langService, child) => Text(
                  langService.getString('student_detail.education_info'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<LanguageService>(
                builder: (context, langService, child) => Column(
                  children: [
                    _buildInfoRow(
                      langService.getString('student_detail.university'),
                      _student!.university ?? '',
                      Icons.account_balance,
                    ),
                    _buildInfoRow(
                      langService.getString('student_detail.department'),
                      _student!.department ?? '',
                      Icons.category,
                    ),
                    _buildInfoRow(
                      langService.getString('student_detail.year_of_study'),
                      _student!.yearOfStudy ?? '',
                      Icons.school,
                    ),
                    _buildInfoRow(
                      langService.getString('student_detail.has_other_degree'),
                      _student!.hasOtherDegree
                          ? langService.getString('common.yes')
                          : langService.getString('common.no'),
                      Icons.emoji_events,
                    ),
                  ],
                ),
              ),
              Consumer<LanguageService>(
                builder: (context, langService, child) => Column(
                  children: [
                    _buildInfoRow(
                      langService.getString('student_detail.registration_date'),
                      _student!.createdAt != null
                          ? '${_student!.createdAt!.day}/${_student!.createdAt!.month}/${_student!.createdAt!.year}'
                          : langService.getString('common.not_provided'),
                      Icons.event,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildContactInfo() => Card(
        child: Padding(
          padding:
              EdgeInsets.all(ResponsiveUtils.getResponsiveCardPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<LanguageService>(
                builder: (context, langService, child) => Text(
                  langService.getString('student_detail.contact_info'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<LanguageService>(
                builder: (context, langService, child) => Column(
                  children: [
                    _buildInfoRow(
                      langService.getString('student_detail.email'),
                      _student!.email,
                      Icons.email,
                    ),
                    _buildInfoRow(
                      langService.getString('student_detail.phone'),
                      _student!.phone ?? '',
                      Icons.phone,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildParentInfo() => Card(
        child: Padding(
          padding:
              EdgeInsets.all(ResponsiveUtils.getResponsiveCardPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<LanguageService>(
                builder: (context, langService, child) => Text(
                  langService.getString('student_detail.parent_info'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              if (_student!.fatherJob?.isNotEmpty ?? false)
                Consumer<LanguageService>(
                  builder: (context, langService, child) => _buildInfoRow(
                    langService.getString('student_detail.father_job'),
                    _student!.fatherJob ?? '',
                    Icons.work,
                  ),
                ),
              if (_student!.motherJob?.isNotEmpty ?? false)
                Consumer<LanguageService>(
                  builder: (context, langService, child) => _buildInfoRow(
                    langService.getString('student_detail.mother_job'),
                    _student!.motherJob ?? '',
                    Icons.work,
                  ),
                ),
              if (_student!.parentAddress?.isNotEmpty ?? false)
                Consumer<LanguageService>(
                  builder: (context, langService, child) => _buildInfoRow(
                    langService.getString('student_detail.address'),
                    _student!.fullParentAddress,
                    Icons.home,
                  ),
                ),
              if (_student!.parentPhone?.isNotEmpty ?? false)
                Consumer<LanguageService>(
                  builder: (context, langService, child) => _buildInfoRow(
                    langService.getString('student_detail.parent_phone'),
                    _student!.parentPhone ?? '',
                    Icons.phone,
                  ),
                ),
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
                    value.isEmpty
                        ? Provider.of<LanguageService>(context, listen: false)
                            .getString('common.not_provided')
                        : value,
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

  Widget _buildActionButtons() {
    final isMobile = ResponsiveUtils.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Consumer<LanguageService>(
            builder: (context, langService, child) => ElevatedButton.icon(
              onPressed: () => context.go('/students/edit/${_student!.id}'),
              icon: const Icon(Icons.edit),
              label: Text(langService.getString('student_detail.edit_button')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: ResponsiveUtils.getResponsiveButtonPadding(context),
              ),
            ),
          ),
          SizedBox(
            height: ResponsiveUtils.getResponsiveVerticalSpacing(context),
          ),
          ElevatedButton.icon(
            onPressed: _isDeleting ? null : _deleteStudent,
            icon: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.delete),
            label: Consumer<LanguageService>(
              builder: (context, langService, child) => Text(
                langService.getString('student_detail.delete_button'),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: ResponsiveUtils.getResponsiveButtonPadding(context),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Consumer<LanguageService>(
          builder: (context, langService, child) => ElevatedButton.icon(
            onPressed: () => context.go('/students/edit/${_student!.id}'),
            icon: const Icon(Icons.edit),
            label: Text(langService.getString('student_detail.edit_button')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: ResponsiveUtils.getResponsiveButtonPadding(context),
            ),
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
          label: Consumer<LanguageService>(
            builder: (context, langService, child) => Text(
              langService.getString('student_detail.delete_button'),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: ResponsiveUtils.getResponsiveButtonPadding(context),
          ),
        ),
      ],
    );
  }
}
