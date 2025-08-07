import 'package:flutter/material.dart';
import '../models/student.dart';

class PaginatedStudentList extends StatelessWidget {

  const PaginatedStudentList({
    required this.students, required this.currentPage, required this.totalPages, required this.onPageChanged, required this.onStudentTap, super.key,
  });
  final List<Student> students;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final Function(Student) onStudentTap;

  @override
  Widget build(BuildContext context) => Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(student.fullName),
                  subtitle: Text(
                    '${student.university} - ${student.department}',
                  ),
                  trailing: Text(student.yearOfStudy),
                  onTap: () => onStudentTap(student),
                ),
              );
            },
          ),
        ),
        _buildPaginationControls(),
      ],
    );

  Widget _buildPaginationControls() {
    // Implementation for pagination controls
    return Container(); // Simplified for brevity
  }
}
