import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/student.dart';
import '../services/excel_service.dart';
import '../services/language_service.dart';
import '../services/student_service.dart';
import '../utils/desktop_constants.dart';
import '../widgets/desktop_students_table.dart';
import '../widgets/loading_widget.dart';
import '../widgets/student_detail_dialog.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final StudentService _studentService = StudentService();
  final TextEditingController _searchController = TextEditingController();

  List<Student> _students = [];
  List<String> _universities = [];
  List<String> _departments = [];
  List<String> _yearsOfStudy = [];

  bool _isLoading = false;
  bool _isExporting = false;

  // Pagination
  int _currentPage = 0;
  int _studentsPerPage = 25;
  int _totalStudents = 0;

  // Filters
  String _searchQuery = '';
  String? _selectedUniversity;
  String? _selectedDepartment;
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadStudents(), _loadFilterOptions()]);
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final students = await _studentService.getStudents(
        limit: _studentsPerPage,
        offset: _currentPage * _studentsPerPage,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        university: _selectedUniversity,
        department: _selectedDepartment,
        yearOfStudy: _selectedYear,
      );

      final totalCount = await _studentService.getTotalStudentsCount(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        university: _selectedUniversity,
        department: _selectedDepartment,
        yearOfStudy: _selectedYear,
      );

      setState(() {
        _students = students;
        _totalStudents = totalCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFilterOptions() async {
    try {
      final universities = await _studentService.getUniversities();
      final departments = await _studentService.getDepartments();
      final years = await _studentService.getYearsOfStudy();

      setState(() {
        _universities = universities;
        _departments = departments;
        _yearsOfStudy = years;
      });
    } catch (e) {
      // Handle error silently for filter options
    }
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 0;
    });
    _loadStudents();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedUniversity = null;
      _selectedDepartment = null;
      _selectedYear = null;
      _currentPage = 0;
    });
    _loadStudents();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadStudents();
  }

  Future<void> _exportFilteredData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final allStudents = await _studentService.getAllStudentsForExport();

      final langService = Provider.of<LanguageService>(context, listen: false);

      // Prepare localized headers
      final localizedHeaders = {
        'id': langService.getString('student_form.export_headers.id'),
        'name': langService.getString('student_form.export_headers.name'),
        'family_name':
            langService.getString('student_form.export_headers.family_name'),
        'father_name':
            langService.getString('student_form.export_headers.father_name'),
        'mother_name':
            langService.getString('student_form.export_headers.mother_name'),
        'birth_date':
            langService.getString('student_form.export_headers.birth_date'),
        'birth_place':
            langService.getString('student_form.export_headers.birth_place'),
        'id_card_number':
            langService.getString('student_form.export_headers.id_card_number'),
        'issuing_authority': langService
            .getString('student_form.export_headers.issuing_authority'),
        'university':
            langService.getString('student_form.export_headers.university'),
        'department':
            langService.getString('student_form.export_headers.department'),
        'year_of_study':
            langService.getString('student_form.export_headers.year_of_study'),
        'has_other_degree': langService
            .getString('student_form.export_headers.has_other_degree'),
        'email': langService.getString('student_form.export_headers.email'),
        'phone': langService.getString('student_form.export_headers.phone'),
        'tax_number':
            langService.getString('student_form.export_headers.tax_number'),
        'father_job':
            langService.getString('student_form.export_headers.father_job'),
        'mother_job':
            langService.getString('student_form.export_headers.mother_job'),
        'parent_address':
            langService.getString('student_form.export_headers.parent_address'),
        'parent_city':
            langService.getString('student_form.export_headers.parent_city'),
        'parent_region':
            langService.getString('student_form.export_headers.parent_region'),
        'parent_postal':
            langService.getString('student_form.export_headers.parent_postal'),
        'parent_country':
            langService.getString('student_form.export_headers.parent_country'),
        'created_at':
            langService.getString('student_form.export_headers.created_at'),
        'yes': langService.getString('student_form.export_headers.yes'),
        'no': langService.getString('student_form.export_headers.no'),
      };

      final localizedTitles = {
        'students_data':
            langService.getString('student_form.export_titles.students_data'),
        'save_excel_title':
            langService.getString('student_form.export_files.save_excel_title'),
        'students_export':
            langService.getString('student_form.export_files.students_export'),
      };

      await ExcelService.exportStudentsToExcel(
        allStudents,
        localizedHeaders: localizedHeaders,
        localizedTitles: localizedTitles,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LanguageService>(
              builder: (context, langService, child) => Text(
                langService.getString('messages.data_exported_success'),
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LanguageService>(
              builder: (context, langService, child) => Text(
                langService.getString(
                  'messages.export_failed',
                  params: {'error': e.toString()},
                ),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _deleteStudent(Student student) async {
    try {
      await _studentService.deleteStudent(student.id ?? "");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LanguageService>(
              builder: (context, langService, child) => Text(
                langService.getString(
                  'messages.student_deleted_success',
                  params: {'name': student.fullName},
                ),
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
        await _loadStudents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LanguageService>(
              builder: (context, langService, child) => Text(
                langService.getString(
                  'messages.delete_student_failed',
                  params: {'error': e.toString()},
                ),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewStudent(Student student) {
    showDialog(
      context: context,
      builder: (context) => StudentDetailDialog(student: student),
    );
  }

  void _editStudent(Student student) {
    context.go('/students/edit/${student.id}');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isVerySmall = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/students/add'),
        icon: const Icon(Icons.add),
        label: Consumer<LanguageService>(
          builder: (context, langService, child) =>
              Text(langService.getString('buttons.add_student')),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header and Filters
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<LanguageService>(
                          builder: (context, langService, child) => Text(
                            langService.students,
                            style: GoogleFonts.poppins(
                              fontSize: isVerySmall ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveUtils.getResponsiveVerticalSpacing(
                                context,
                              ) *
                              0.5,
                        ),
                        Consumer<LanguageService>(
                          builder: (context, langService, child) => Text(
                            langService.getString('students.subtitle'),
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                14,
                              ),
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveUtils.getResponsiveVerticalSpacing(
                            context,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: ResponsiveUtils.getResponsiveButtonHeight(
                            context,
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/students/add'),
                            icon: Icon(
                              Icons.add,
                              size: ResponsiveUtils.getResponsiveIconSize(
                                context,
                                20,
                              ),
                            ),
                            label: Consumer<LanguageService>(
                              builder: (context, langService, child) => Text(
                                langService.getString('buttons.add_student'),
                                style: TextStyle(
                                  fontSize:
                                      ResponsiveUtils.getResponsiveFontSize(
                                    context,
                                    14,
                                  ),
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer<LanguageService>(
                                builder: (context, langService, child) => Text(
                                  langService.students,
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Consumer<LanguageService>(
                                builder: (context, langService, child) => Text(
                                  langService.getString('students.subtitle'),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/students/add'),
                          icon: const Icon(Icons.add),
                          label: Consumer<LanguageService>(
                            builder: (context, langService, child) => Text(
                              langService.getString('buttons.add_student'),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(
                    height: ResponsiveUtils.getResponsiveVerticalSpacing(
                      context,
                    ),
                  ),

                  // Search and Filters
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        ResponsiveUtils.getResponsiveCardPadding(context),
                      ),
                      child: Column(
                        children: [
                          // Search Bar
                          if (isMobile)
                            Column(
                              children: [
                                TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: context
                                        .read<LanguageService>()
                                        .getString('ui.search_placeholder'),
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveUtils
                                          .getResponsiveHorizontalSpacing(
                                        context,
                                      ),
                                      vertical: 12,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                  onSubmitted: (_) => _applyFilters(),
                                ),
                                SizedBox(
                                  height: ResponsiveUtils
                                      .getResponsiveVerticalSpacing(
                                    context,
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _applyFilters,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: Consumer<LanguageService>(
                                      builder: (context, langService, child) =>
                                          Text(
                                        langService
                                            .getString('ui.search_button'),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: context
                                          .read<LanguageService>()
                                          .getString('ui.search_placeholder'),
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                    onSubmitted: (_) => _applyFilters(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: _applyFilters,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                  ),
                                  child: Consumer<LanguageService>(
                                    builder: (context, langService, child) =>
                                        Text(
                                      langService.getString('ui.search_button'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          SizedBox(
                            height:
                                ResponsiveUtils.getResponsiveVerticalSpacing(
                              context,
                            ),
                          ),

                          // Filter Dropdowns
                          if (isMobile)
                            Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _selectedUniversity,
                                  decoration: InputDecoration(
                                    labelText: context
                                        .read<LanguageService>()
                                        .getString('ui.university_label'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      child: Consumer<LanguageService>(
                                        builder:
                                            (context, langService, child) =>
                                                Text(
                                          langService.getString(
                                            'ui.all_universities',
                                          ),
                                        ),
                                      ),
                                    ),
                                    ..._universities.map(
                                      (uni) => DropdownMenuItem(
                                        value: uni,
                                        child: Text(uni),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUniversity = value;
                                    });
                                  },
                                ),
                                SizedBox(
                                  height: ResponsiveUtils
                                          .getResponsiveVerticalSpacing(
                                        context,
                                      ) *
                                      0.75,
                                ),
                                DropdownButtonFormField<String>(
                                  value: _selectedDepartment,
                                  decoration: InputDecoration(
                                    labelText: context
                                        .read<LanguageService>()
                                        .getString('ui.department_label'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      child: Consumer<LanguageService>(
                                        builder:
                                            (context, langService, child) =>
                                                Text(
                                          langService
                                              .getString('ui.all_departments'),
                                        ),
                                      ),
                                    ),
                                    ..._departments.map(
                                      (dept) => DropdownMenuItem(
                                        value: dept,
                                        child: Text(dept),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDepartment = value;
                                    });
                                  },
                                ),
                                SizedBox(
                                  height: ResponsiveUtils
                                          .getResponsiveVerticalSpacing(
                                        context,
                                      ) *
                                      0.75,
                                ),
                                DropdownButtonFormField<String>(
                                  value: _selectedYear,
                                  decoration: InputDecoration(
                                    labelText: context
                                        .read<LanguageService>()
                                        .getString('ui.year_of_study_label'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      child: Consumer<LanguageService>(
                                        builder:
                                            (context, langService, child) =>
                                                Text(
                                          langService.getString('ui.all_years'),
                                        ),
                                      ),
                                    ),
                                    ..._yearsOfStudy.map(
                                      (year) => DropdownMenuItem(
                                        value: year,
                                        child: Consumer<LanguageService>(
                                          builder:
                                              (context, langService, child) =>
                                                  Text(
                                            '${langService.getString('ui.year_prefix')} $year',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedYear = value;
                                    });
                                  },
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedUniversity,
                                    decoration: InputDecoration(
                                      labelText: context
                                          .read<LanguageService>()
                                          .getString('ui.university_label'),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        child: Consumer<LanguageService>(
                                          builder:
                                              (context, langService, child) =>
                                                  Text(
                                            langService.getString(
                                              'ui.all_universities',
                                            ),
                                          ),
                                        ),
                                      ),
                                      ..._universities.map(
                                        (uni) => DropdownMenuItem(
                                          value: uni,
                                          child: Text(uni),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedUniversity = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedDepartment,
                                    decoration: InputDecoration(
                                      labelText: context
                                          .read<LanguageService>()
                                          .getString('ui.department_label'),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        child: Consumer<LanguageService>(
                                          builder:
                                              (context, langService, child) =>
                                                  Text(
                                            langService.getString(
                                              'ui.all_departments',
                                            ),
                                          ),
                                        ),
                                      ),
                                      ..._departments.map(
                                        (dept) => DropdownMenuItem(
                                          value: dept,
                                          child: Text(dept),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedDepartment = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedYear,
                                    decoration: InputDecoration(
                                      labelText: context
                                          .read<LanguageService>()
                                          .getString('ui.year_of_study_label'),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        child: Consumer<LanguageService>(
                                          builder:
                                              (context, langService, child) =>
                                                  Text(
                                            langService
                                                .getString('ui.all_years'),
                                          ),
                                        ),
                                      ),
                                      ..._yearsOfStudy.map(
                                        (year) => DropdownMenuItem(
                                          value: year,
                                          child: Consumer<LanguageService>(
                                            builder:
                                                (context, langService, child) =>
                                                    Text(
                                              '${langService.getString('ui.year_prefix')} $year',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedYear = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          // Clear Filters Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _clearFilters,
                                icon: const Icon(Icons.clear, size: 18),
                                label: Consumer<LanguageService>(
                                  builder: (context, langService, child) =>
                                      Text(
                                    langService
                                        .getString('messages.clear_filters'),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.grey[700],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Consumer<LanguageService>(
                    builder: (context, langService, child) => Text(
                      langService.getString(
                        'messages.showing_results',
                        params: {
                          'count': _students.length.toString(),
                          'total': _totalStudents.toString(),
                        },
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_totalStudents > 0) ...[
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportFilteredData,
                      icon: _isExporting
                          ? SizedBox(
                              width: ResponsiveUtils.getResponsiveIconSize(
                                context,
                                16,
                              ),
                              height: ResponsiveUtils.getResponsiveIconSize(
                                context,
                                16,
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.download,
                              size: ResponsiveUtils.getResponsiveIconSize(
                                context,
                                18,
                              ),
                            ),
                      label: Consumer<LanguageService>(
                        builder: (context, langService, child) => Text(
                          _isExporting
                              ? langService.getString('messages.exporting')
                              : langService.getString('messages.export_button'),
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              14,
                            ),
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              ResponsiveUtils.getResponsiveHorizontalSpacing(
                            context,
                          ),
                          vertical: isMobile ? 12 : 8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),

            // Students Table
            SizedBox(
              height: MediaQuery.of(context).size.height - 400,
              child: _isLoading
                  ? Consumer<LanguageService>(
                      builder: (context, langService, child) => LoadingWidget(
                        message:
                            langService.getString('messages.loading_students'),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: DesktopStudentsTable(
                            students: _students,
                            onView: _viewStudent,
                            onEdit: _editStudent,
                            onDelete: _deleteStudent,
                            onRefresh: _loadStudents,
                          ),
                        ),
                        // Pagination inside the expanded area
                        if (_totalStudents > _studentsPerPage)
                          _buildPaginationControls(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_totalStudents / _studentsPerPage).ceil();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${_currentPage + 1} of $totalPages',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
          ),
          Row(
            children: [
              // Items per page
              Text(
                'Items per page:',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 6),
              DropdownButton<int>(
                value: _studentsPerPage,
                isDense: true,
                items: [10, 25, 50, 100]
                    .map(
                      (int value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text(
                          value.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _studentsPerPage = value;
                      _currentPage = 0;
                    });
                    _loadStudents();
                  }
                },
              ),
              const SizedBox(width: 16),

              // Pagination buttons
              IconButton(
                onPressed: _currentPage > 0
                    ? () => _onPageChanged(_currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              const SizedBox(width: 8),

              // Page numbers
              ...List.generate(totalPages > 7 ? 7 : totalPages, (index) {
                int pageNumber;
                if (totalPages <= 7) {
                  pageNumber = index;
                } else if (_currentPage < 3) {
                  pageNumber = index;
                } else if (_currentPage > totalPages - 4) {
                  pageNumber = totalPages - 7 + index;
                } else {
                  pageNumber = _currentPage - 3 + index;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: TextButton(
                    onPressed: () => _onPageChanged(pageNumber),
                    style: TextButton.styleFrom(
                      backgroundColor: pageNumber == _currentPage
                          ? Colors.blue[600]
                          : Colors.transparent,
                      foregroundColor: pageNumber == _currentPage
                          ? Colors.white
                          : Colors.grey[700],
                      minimumSize: const Size(32, 32),
                    ),
                    child: Text((pageNumber + 1).toString()),
                  ),
                );
              }),

              const SizedBox(width: 8),
              IconButton(
                onPressed: _currentPage < totalPages - 1
                    ? () => _onPageChanged(_currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
