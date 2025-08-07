import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/student.dart';

// Cache DateFormat instances
final _dateFormat = DateFormat('dd/MM/yyyy');
final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

class StudentsDataTable extends StatefulWidget {
  const StudentsDataTable({
    required this.students,
    super.key,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.isLoading = false,
    this.onRefresh,
  });
  final List<Student> students;
  final Function(Student)? onEdit;
  final Function(Student)? onDelete;
  final Function(Student)? onView;
  final bool isLoading;
  final VoidCallback? onRefresh;

  @override
  State<StudentsDataTable> createState() => _StudentsDataTableState();
}

class _StudentsDataTableState extends State<StudentsDataTable>
    with AutomaticKeepAliveClientMixin {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  late List<Student> _sortedStudents;
  late ScrollController _verticalScrollController;
  late ScrollController _horizontalScrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _sortedStudents = List.from(widget.students);
    _verticalScrollController = ScrollController();
    _horizontalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StudentsDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.students != widget.students) {
      _sortedStudents = List.from(widget.students);
      _applySorting();
    }
  }

  void _sort<T>(Comparable<T> Function(Student) getField, int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
    });
    _applySorting();
  }

  void _applySorting() {
    _sortedStudents.sort((a, b) {
      Comparable aValue;
      Comparable bValue;

      switch (_sortColumnIndex) {
        case 0:
          aValue = a.name.toLowerCase();
          bValue = b.name.toLowerCase();
          break;
        case 1:
          aValue = a.familyName.toLowerCase();
          bValue = b.familyName.toLowerCase();
          break;
        case 2:
          aValue = a.email.toLowerCase();
          bValue = b.email.toLowerCase();
          break;
        case 3:
          aValue = a.university.toLowerCase();
          bValue = b.university.toLowerCase();
          break;
        case 4:
          aValue = a.department.toLowerCase();
          bValue = b.department.toLowerCase();
          break;
        case 5:
          aValue = a.yearOfStudy;
          bValue = b.yearOfStudy;
          break;
        case 6:
          aValue = a.phone;
          bValue = b.phone;
          break;
        case 7:
          aValue = a.createdAt;
          bValue = b.createdAt;
          break;
        default:
          aValue = a.name.toLowerCase();
          bValue = b.name.toLowerCase();
      }

      return _sortAscending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });
  }

  void _showDeleteDialog(Student student) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
          'Are you sure you want to delete ${student.name} ${student.familyName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call(student);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return _buildContent();
  }

  Widget _buildContent() => Card(
        elevation: 1,
        margin: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Students (${_sortedStudents.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  if (widget.onRefresh != null)
                    IconButton(
                      onPressed: widget.onRefresh,
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Refresh',
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: MediaQuery.of(context).size.width < 600
                  ? _buildMobileLayout()
                  : _buildDesktopLayout(),
            ),
          ],
        ),
      );

  Widget _buildDesktopLayout() {
    if (_sortedStudents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No students found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        child: Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (ScrollNotification notification) =>
              notification.depth == 1,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width:
                  1400, // Increased width to ensure horizontal scrolling is needed
              child: DataTable(
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                headingRowColor:
                    const WidgetStatePropertyAll(Color(0xFFF8F9FA)),
                headingTextStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
                headingRowHeight: 44,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 48,
                columnSpacing: 24,
                horizontalMargin: 20,
                columns: [
                  DataColumn(
                    label: const Text('Name'),
                    onSort: (columnIndex, ascending) => _sort(
                      (student) => student.name.toLowerCase(),
                      columnIndex,
                    ),
                  ),
                  DataColumn(
                    label: const Text('Family Name'),
                    onSort: (columnIndex, ascending) => _sort(
                      (student) => student.familyName.toLowerCase(),
                      columnIndex,
                    ),
                  ),
                  DataColumn(
                    label: const Text('Email'),
                    onSort: (columnIndex, ascending) => _sort(
                      (student) => student.email.toLowerCase(),
                      columnIndex,
                    ),
                  ),
                  DataColumn(
                    label: const Text('University'),
                    onSort: (columnIndex, ascending) => _sort(
                      (student) => student.university.toLowerCase(),
                      columnIndex,
                    ),
                  ),
                  DataColumn(
                    label: const Text('Department'),
                    onSort: (columnIndex, ascending) => _sort(
                      (student) => student.department.toLowerCase(),
                      columnIndex,
                    ),
                  ),
                  DataColumn(
                    label: const Text('Year'),
                    onSort: (columnIndex, ascending) =>
                        _sort((student) => student.yearOfStudy, columnIndex),
                  ),
                  const DataColumn(label: Text('Phone')),
                  DataColumn(
                    label: const Text('Created'),
                    onSort: (columnIndex, ascending) =>
                        _sort((student) => student.createdAt, columnIndex),
                  ),
                  const DataColumn(label: Text('Actions')),
                ],
                rows: _sortedStudents
                    .map(
                      (student) => DataRow(
                        key: ValueKey(student.id),
                        cells: [
                          DataCell(Text(student.name)),
                          DataCell(Text(student.familyName)),
                          DataCell(
                            Text(
                              student.email,
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                          DataCell(Text(student.university)),
                          DataCell(Text(student.department)),
                          DataCell(Text(student.yearOfStudy)),
                          DataCell(Text(student.phone)),
                          DataCell(Text(_dateFormat.format(student.createdAt))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.onView != null)
                                  IconButton(
                                    onPressed: () => widget.onView!(student),
                                    icon:
                                        const Icon(Icons.visibility, size: 16),
                                    tooltip: 'students.actions.view'.tr(),
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                if (widget.onEdit != null)
                                  IconButton(
                                    onPressed: () => widget.onEdit!(student),
                                    icon: const Icon(Icons.edit, size: 16),
                                    tooltip: 'students.actions.edit'.tr(),
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                if (widget.onDelete != null)
                                  IconButton(
                                    onPressed: () => _showDeleteDialog(student),
                                    icon: const Icon(Icons.delete, size: 16),
                                    color: Colors.red,
                                    tooltip: 'students.actions.delete'.tr(),
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    if (_sortedStudents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No students found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      itemCount: _sortedStudents.length,
      cacheExtent: 1000,
      itemBuilder: (context, index) {
        final student = _sortedStudents[index];
        return StudentMobileCard(
          key: ValueKey(student.id),
          student: student,
          onView: widget.onView,
          onEdit: widget.onEdit,
          onDelete:
              widget.onDelete != null ? () => _showDeleteDialog(student) : null,
        );
      },
    );
  }
}

class StudentMobileCard extends StatelessWidget {
  const StudentMobileCard({
    required this.student,
    super.key,
    this.onView,
    this.onEdit,
    this.onDelete,
  });
  final Student student;
  final Function(Student)? onView;
  final Function(Student)? onEdit;
  final VoidCallback? onDelete;

  static const _leadingStyle = TextStyle(
    color: Colors.blue,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );

  static const _titleStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 14,
  );

  static const _subtitleStyle = TextStyle(color: Colors.grey, fontSize: 12);

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            radius: 16,
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
              style: _leadingStyle,
            ),
          ),
          title: Text(
            '${student.name} ${student.familyName}',
            style: _titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            student.email,
            style: _subtitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onView != null)
                IconButton(
                  onPressed: () => onView!(student),
                  icon: const Icon(Icons.visibility, size: 16),
                  tooltip: 'students.actions.view'.tr(),
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              if (onEdit != null)
                IconButton(
                  onPressed: () => onEdit!(student),
                  icon: const Icon(Icons.edit, size: 16),
                  tooltip: 'students.actions.edit'.tr(),
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 16),
                  color: Colors.red,
                  tooltip: 'students.actions.delete'.tr(),
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  _buildDetailRow('Phone', student.phone),
                  _buildDetailRow("Father's Name", student.fatherName),
                  _buildDetailRow("Mother's Name", student.motherName),
                  _buildDetailRow(
                    'Birth Date',
                    _dateFormat.format(student.birthDate),
                  ),
                  _buildDetailRow('University', student.university),
                  _buildDetailRow('Department', student.department),
                  _buildDetailRow('Year of Study', student.yearOfStudy),
                  _buildDetailRow(
                    'Created',
                    _dateTimeFormat.format(student.createdAt),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  static const _labelStyle = TextStyle(
    fontWeight: FontWeight.w500,
    color: Colors.grey,
    fontSize: 11,
  );

  static const _valueStyle = TextStyle(color: Colors.black87, fontSize: 11);

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: Text(label, style: _labelStyle)),
            Expanded(flex: 3, child: Text(value, style: _valueStyle)),
          ],
        ),
      );
}
