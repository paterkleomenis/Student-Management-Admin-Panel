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
      final students = await _studentService.getAllStudentsForExport();
      await ExcelService.exportStudentsToExcel(students);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully!'),
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
                      child: Consumer<LanguageService>(
                        builder: (context, langService, child) => LoadingWidget(
                          message: langService
                              .getString('dashboard.loading_dashboard'),
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      // Statistics Cards
                      _buildStatisticsCards(),
                      DesktopConstants.verticalSpace,

                      // Recent Students
                      _buildRecentStudents(),
                      DesktopConstants.verticalSpace,
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
                Consumer<LanguageService>(
                  builder: (context, langService, child) => Text(
                    langService.dashboard,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<LanguageService>(
                  builder: (context, langService, child) => Text(
                    langService.getString('dashboard.welcome_message'),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
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
              builder: (context, langService, child) => Text(
                _isExporting
                    ? langService.getString('messages.exporting')
                    : langService.getString('dashboard.export_data'),
              ),
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
    final universityCounts =
        _stats['universityCounts'] as Map<String, int>? ?? {};
    final departmentCounts =
        _stats['departmentCounts'] as Map<String, int>? ?? {};

    final cards = [
      Consumer<LanguageService>(
        builder: (context, langService, child) => _buildStatCard(
          langService.getString('dashboard.total_students'),
          totalStudents.toString(),
          Icons.people,
          Colors.blue,
        ),
      ),
      Consumer<LanguageService>(
        builder: (context, langService, child) => _buildStatCard(
          langService.getString('dashboard.universities'),
          universityCounts.length.toString(),
          Icons.school,
          Colors.green,
        ),
      ),
      Consumer<LanguageService>(
        builder: (context, langService, child) => _buildStatCard(
          langService.getString('dashboard.departments'),
          departmentCounts.length.toString(),
          Icons.account_tree,
          Colors.orange,
        ),
      ),
      Consumer<LanguageService>(
        builder: (context, langService, child) => _buildStatCard(
          langService.getString('dashboard.recent'),
          _recentStudents.length.toString(),
          Icons.access_time,
          Colors.purple,
        ),
      ),
    ];

    return Row(
      children: [
        Expanded(child: cards[0]),
        DesktopConstants.horizontalSpace,
        Expanded(child: cards[1]),
        DesktopConstants.horizontalSpace,
        Expanded(child: cards[2]),
        DesktopConstants.horizontalSpace,
        Expanded(child: cards[3]),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
      Container(
        padding: DesktopConstants.cardPaddingInsets,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: DesktopConstants.largeIconSize,
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: DesktopConstants.extraLargeHeaderFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );

  Widget _buildRecentStudents() => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Students',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to students screen
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_recentStudents.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      'No students found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
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
                    return _buildStudentListItem(student);
                  },
                ),
            ],
          ),
        ),
      );

  Widget _buildStudentListItem(Student student) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
            style: TextStyle(
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.fullName,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${student.university} • ${student.department}',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('MMM dd').format(student.createdAt),
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
        onTap: () => _showStudentDetails(student),
      );
}
