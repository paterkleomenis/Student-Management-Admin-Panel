import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/student.dart';

import '../services/excel_service.dart';
import '../services/language_service.dart';
import '../services/student_service.dart';
import '../utils/desktop_constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/student_detail_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StudentService _studentService = StudentService();

  bool _isLoading = true;
  bool _isExporting = false;
  Map<String, dynamic> _stats = {};
  List<Student> _recentStudents = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load statistics
      final stats = await _studentService.getStatistics();

      // Load recent students (limit to 5)
      final recentStudents = await _studentService.getStudents(limit: 5);

      setState(() {
        _stats = stats;
        _recentStudents = recentStudents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportAllData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final langService = Provider.of<LanguageService>(context, listen: false);
      final students = await _studentService.getAllStudentsForExport();

      // Prepare localized headers
      final localizedHeaders = {
        'id': langService.getString('student_form.export_headers.id'),
        'name': langService.getString('student_form.export_headers.name'),
        'family_name': langService.getString('student_form.export_headers.family_name'),
        'father_name': langService.getString('student_form.export_headers.father_name'),
        'mother_name': langService.getString('student_form.export_headers.mother_name'),
        'birth_date': langService.getString('student_form.export_headers.birth_date'),
        'birth_place': langService.getString('student_form.export_headers.birth_place'),
        'id_card_number': langService.getString('student_form.export_headers.id_card_number'),
        'issuing_authority': langService.getString('student_form.export_headers.issuing_authority'),
        'university': langService.getString('student_form.export_headers.university'),
        'department': langService.getString('student_form.export_headers.department'),
        'year_of_study': langService.getString('student_form.export_headers.year_of_study'),
        'has_other_degree': langService.getString('student_form.export_headers.has_other_degree'),
        'email': langService.getString('student_form.export_headers.email'),
        'phone': langService.getString('student_form.export_headers.phone'),
        'tax_number': langService.getString('student_form.export_headers.tax_number'),
        'father_job': langService.getString('student_form.export_headers.father_job'),
        'mother_job': langService.getString('student_form.export_headers.mother_job'),
        'parent_address': langService.getString('student_form.export_headers.parent_address'),
        'parent_city': langService.getString('student_form.export_headers.parent_city'),
        'parent_region': langService.getString('student_form.export_headers.parent_region'),
        'parent_postal': langService.getString('student_form.export_headers.parent_postal'),
        'parent_country': langService.getString('student_form.export_headers.parent_country'),
        'parent_number': langService.getString('student_form.export_headers.parent_number'),
        'created_at': langService.getString('student_form.export_headers.created_at'),
        'yes': langService.getString('student_form.export_headers.yes'),
        'no': langService.getString('student_form.export_headers.no'),
      };

      final localizedTitles = {
        'students_data': langService.getString('student_form.export_titles.students_data'),
        'save_excel_title': langService.getString('student_form.export_files.save_excel_title'),
        'students_export': langService.getString('student_form.export_files.students_export'),
      };

      await ExcelService.exportStudentsToExcel(
        students,
        localizedHeaders: localizedHeaders,
        localizedTitles: localizedTitles,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(langService.getString('messages.data_exported_success')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final langService = Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(langService.getString('messages.export_failed', params: {'error': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showStudentDetails(Student student) {
    showDialog(
      context: context,
      builder: (context) => StudentDetailDialog(student: student),
    );
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: DesktopConstants.contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                DesktopConstants.verticalSpace,

                // Main Content
                if (_isLoading)
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: LoadingWidget(
                        message: 'Loading dashboard...',
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      // Statistics Cards Row
                      _buildStatisticsCards(),
                      DesktopConstants.verticalSpace,

                      // Recent Students
                      _buildRecentStudents(),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _buildHeader() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Overview of dormitory applications and documents',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _isExporting ? null : _exportAllData,
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            label: Consumer<LanguageService>(
              builder: (context, langService, child) => Text(_isExporting
                  ? langService.getString('messages.exporting')
                  : langService.getString('messages.export_button')),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      );

  Widget _buildStatisticsCards() {
    final totalStudents = _stats['totalStudents'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Registrations',
            totalStudents.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentStudents() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Applications',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to students page
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentStudents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No recent applications'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentStudents.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final student = _recentStudents[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        student.name.isNotEmpty
                            ? student.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(student.fullName ?? ""),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.email ?? ""),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.green,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Registered',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Text(
                      DateFormat('MMM dd').format(student.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => _showStudentDetails(student),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
