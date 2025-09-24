import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student.dart';
import '../services/language_service.dart';
import '../services/student_service.dart';
import '../utils/desktop_constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final StudentService _studentService = StudentService();
  List<Student> _students = [];
  bool _isLoading = true;
  final Map<String, int> _universityStats = {};
  final Map<String, int> _departmentStats = {};
  final Map<String, int> _yearStats = {};

  @override
  void initState() {
    super.initState();
    _loadReportsData();
  }

  Future<void> _loadReportsData() async {
    try {
      final students = await _studentService.getAllStudentsForExport();
      setState(() {
        _students = students;
        _calculateStats();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final langService =
            Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              langService.getString(
                'reports.error_loading_data',
                params: {'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _calculateStats() {
    _universityStats.clear();
    _departmentStats.clear();
    _yearStats.clear();

    for (final student in _students) {
      // University statistics
      final langService = Provider.of<LanguageService>(context, listen: false);
      final university =
          student.university ?? langService.getString('common.unknown');
      _universityStats[university] = (_universityStats[university] ?? 0) + 1;

      // Department statistics
      final department =
          student.department ?? langService.getString('common.unknown');
      _departmentStats[department] = (_departmentStats[department] ?? 0) + 1;

      // Year of study statistics
      final yearOfStudy =
          student.yearOfStudy ?? langService.getString('common.unknown');
      _yearStats[yearOfStudy] = (_yearStats[yearOfStudy] ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<LanguageService>(
        builder: (context, langService, child) {
          if (_isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            body: RefreshIndicator(
              onRefresh: _loadReportsData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: DesktopConstants.contentPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(langService),
                    const SizedBox(height: 24),
                    _buildOverviewCards(langService),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildUniversityChart(langService)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDepartmentChart(langService)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildYearOfStudyChart(langService),
                    const SizedBox(height: 24),
                    _buildDetailedStats(langService),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Widget _buildHeader(LanguageService langService) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            langService.getString('reports.title'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Consumer<LanguageService>(
            builder: (context, langService, child) => Text(
              langService.getString('reports.subtitle'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Consumer<LanguageService>(
            builder: (context, langService, child) => Text(
              langService.getString(
                'reports.last_updated',
                params: {
                  'timestamp': DateTime.now().toString().split('.')[0],
                },
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ),
        ],
      );

  Widget _buildOverviewCards(LanguageService langService) {
    final totalStudents = _students.length;
    final studentsWithOtherDegree =
        _students.where((s) => s.hasOtherDegree).length;
    final uniqueUniversities = _universityStats.keys.length;
    final uniqueDepartments = _departmentStats.keys.length;

    return Row(
      children: [
        Expanded(
          child: Consumer<LanguageService>(
            builder: (context, langService, child) => _buildStatCard(
              langService.getString('reports.total_students'),
              totalStudents.toString(),
              Icons.school,
              Colors.blue,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Consumer<LanguageService>(
            builder: (context, langService, child) => _buildStatCard(
              langService.getString('reports.universities'),
              uniqueUniversities.toString(),
              Icons.account_balance,
              Colors.green,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Consumer<LanguageService>(
            builder: (context, langService, child) => _buildStatCard(
              langService.getString('reports.departments'),
              uniqueDepartments.toString(),
              Icons.category,
              Colors.orange,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Consumer<LanguageService>(
            builder: (context, langService, child) => _buildStatCard(
              langService.getString('reports.with_other_degree'),
              studentsWithOtherDegree.toString(),
              Icons.emoji_events,
              Colors.purple,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
      Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildUniversityChart(LanguageService langService) {
    if (_universityStats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Consumer<LanguageService>(
              builder: (context, langService, child) => Text(
                langService.getString('reports.no_university_data'),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<LanguageService>(
              builder: (context, langService, child) => Text(
                langService.getString('reports.students_by_university'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: _universityStats.entries
                      .take(5)
                      .map(
                        (entry) => PieChartSectionData(
                          value: entry.value.toDouble(),
                          title: entry.value.toString(),
                          radius: 100,
                          color: _getColorForIndex(
                            _universityStats.keys.toList().indexOf(entry.key),
                          ),
                        ),
                      )
                      .toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildChartLegend(_universityStats),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentChart(LanguageService langService) {
    if (_departmentStats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Consumer<LanguageService>(
              builder: (context, langService, child) => Text(
                langService.getString('reports.no_department_data'),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<LanguageService>(
              builder: (context, langService, child) => Text(
                langService.getString('reports.students_by_department'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _departmentStats.values
                          .reduce((a, b) => a > b ? a : b)
                          .toDouble() +
                      1,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          final departments = _departmentStats.keys.toList();
                          if (index >= 0 && index < departments.length) {
                            final dept = departments[index];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dept.length > 10
                                    ? '${dept.substring(0, 10)}...'
                                    : dept,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _departmentStats.entries
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (mapEntry) => BarChartGroupData(
                          x: mapEntry.key,
                          barRods: [
                            BarChartRodData(
                              toY: mapEntry.value.value.toDouble(),
                              color: _getColorForIndex(mapEntry.key),
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearOfStudyChart(LanguageService langService) {
    if (_yearStats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Consumer<LanguageService>(
              builder: (context, langService, child) => Text(
                langService.getString('reports.no_year_data'),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<LanguageService>(
              builder: (context, langService, child) => Text(
                langService.getString('reports.students_by_year'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final years = _yearStats.keys.toList()..sort();
                          final index = value.toInt();
                          if (index >= 0 && index < years.length) {
                            return Text(
                              years[index],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _yearStats.entries
                          .toList()
                          .asMap()
                          .entries
                          .map(
                            (entry) => FlSpot(
                              entry.key.toDouble(),
                              entry.value.value.toDouble(),
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats(LanguageService langService) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<LanguageService>(
                builder: (context, langService, child) => Text(
                  langService.getString('reports.detailed_statistics'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<LanguageService>(
                builder: (context, langService, child) => Column(
                  children: [
                    _buildStatRow(
                      langService.getString('reports.total_students'),
                      _students.length.toString(),
                    ),
                    _buildStatRow(
                      langService.getString('reports.average_age'),
                      _calculateAverageAge(),
                    ),
                    _buildStatRow(
                      langService
                          .getString('reports.students_with_other_degree'),
                      _students
                          .where((s) => s.hasOtherDegree)
                          .length
                          .toString(),
                    ),
                  ],
                ),
              ),
              Consumer<LanguageService>(
                builder: (context, langService, child) => _buildStatRow(
                  langService.getString('reports.most_popular_university'),
                  _getMostPopularUniversity(),
                ),
              ),
              Consumer<LanguageService>(
                builder: (context, langService, child) => Column(
                  children: [
                    _buildStatRow(
                      langService.getString('reports.most_popular_department'),
                      _getMostPopularDepartment(),
                    ),
                    _buildStatRow(
                      langService.getString('reports.most_common_year'),
                      _getMostCommonYear(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildStatRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );

  Widget _buildChartLegend(Map<String, int> stats) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: stats.entries.take(5).map((entry) {
          final index = stats.keys.toList().indexOf(entry.key);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getColorForIndex(index),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                entry.key.length > 15
                    ? '${entry.key.substring(0, 15)}...'
                    : entry.key,
                style: const TextStyle(fontSize: 12),
              ),
              Text(' (${entry.value})', style: const TextStyle(fontSize: 12)),
            ],
          );
        }).toList(),
      );

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  String _calculateAverageAge() {
    if (_students.isEmpty) return '0';
    final now = DateTime.now();
    final studentsWithBirthDate =
        _students.where((student) => student.birthDate != null).toList();
    if (studentsWithBirthDate.isEmpty) return '0';
    final totalAge = studentsWithBirthDate.fold<int>(
      0,
      (sum, student) => sum + now.difference(student.birthDate!).inDays ~/ 365,
    );
    return (totalAge / studentsWithBirthDate.length).toStringAsFixed(1);
  }

  String _getMostPopularUniversity() {
    if (_universityStats.isEmpty) {
      return Provider.of<LanguageService>(context, listen: false)
          .getString('common.not_provided');
    }
    final mostPopular =
        _universityStats.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${mostPopular.key} (${mostPopular.value})';
  }

  String _getMostPopularDepartment() {
    if (_departmentStats.isEmpty) {
      return Provider.of<LanguageService>(context, listen: false)
          .getString('common.not_provided');
    }
    final mostPopular =
        _departmentStats.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${mostPopular.key} (${mostPopular.value})';
  }

  String _getMostCommonYear() {
    if (_yearStats.isEmpty) {
      return Provider.of<LanguageService>(context, listen: false)
          .getString('common.not_provided');
    }
    final mostCommon =
        _yearStats.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${mostCommon.key} (${mostCommon.value})';
  }
}
