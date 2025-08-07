import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../services/language_service.dart';

class DesktopStudentsTable extends StatefulWidget {
  const DesktopStudentsTable({
    required this.students,
    super.key,
    this.onView,
    this.onEdit,
    this.onDelete,
    this.onRefresh,
  });

  final List<Student> students;
  final Function(Student)? onView;
  final Function(Student)? onEdit;
  final Function(Student)? onDelete;
  final VoidCallback? onRefresh;

  @override
  State<DesktopStudentsTable> createState() => _DesktopStudentsTableState();
}

class _DesktopStudentsTableState extends State<DesktopStudentsTable> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _actionsScrollController = ScrollController();

  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  List<Student> _sortedStudents = [];

  @override
  void initState() {
    super.initState();
    _sortedStudents = List.from(widget.students);
    _applySorting();
    _verticalScrollController.addListener(_syncScrolling);
    _horizontalScrollController.addListener(_syncHorizontalScrolling);
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _headerScrollController.dispose();
    _verticalScrollController.dispose();
    _actionsScrollController.dispose();
    super.dispose();
  }

  void _syncScrolling() {
    if (_actionsScrollController.hasClients &&
        _verticalScrollController.hasClients) {
      if (_actionsScrollController.offset != _verticalScrollController.offset) {
        _actionsScrollController.jumpTo(_verticalScrollController.offset);
      }
    }
  }

  void _syncHorizontalScrolling() {
    if (_headerScrollController.hasClients &&
        _horizontalScrollController.hasClients) {
      if (_headerScrollController.offset !=
          _horizontalScrollController.offset) {
        _headerScrollController.jumpTo(_horizontalScrollController.offset);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<LanguageService>(
        builder: (context, langService, child) =>
            _buildDesktopView(langService),
      );

  Widget _buildDesktopView(LanguageService langService) {
    if (widget.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              langService.getString('students.no_students'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    const double actionsWidth = 160;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _headerScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _calculateContentWidth(screenWidth),
                    child: Row(
                      children: _buildHeaderCells(screenWidth, langService),
                    ),
                  ),
                ),
              ),
              Container(
                width: actionsWidth,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  border: Border(left: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Center(
                  child: Text(
                    langService.actions,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Scrollbar(
                  controller: _horizontalScrollController,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _calculateContentWidth(screenWidth),
                      child: Scrollbar(
                        controller: _verticalScrollController,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _verticalScrollController,
                          itemCount: _sortedStudents.length,
                          itemBuilder: (context, index) {
                            final student = _sortedStudents[index];
                            return _buildDataRow(
                              student,
                              screenWidth,
                              index,
                              langService,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: actionsWidth,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Scrollbar(
                  controller: _actionsScrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _actionsScrollController,
                    itemCount: _sortedStudents.length,
                    itemBuilder: (context, index) {
                      final student = _sortedStudents[index];
                      return Container(
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: _buildActionsRow(student, langService),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateContentWidth(double screenWidth) => 3085;

  List<Widget> _buildHeaderCells(
    double screenWidth,
    LanguageService langService,
  ) =>
      [
        _buildHeaderCell(langService.studentId, 95, 0),
        _buildHeaderCell(langService.studentName, 115, 1),
        _buildHeaderCell(langService.studentFamilyName, 115, 2),
        _buildHeaderCell(langService.studentFatherName, 115, 3),
        _buildHeaderCell(langService.studentMotherName, 115, 4),
        _buildHeaderCell(langService.studentBirthDate, 105, 5),
        _buildHeaderCell(langService.studentBirthPlace, 125, 6),
        _buildHeaderCell(langService.studentIdCard, 115, 7),
        _buildHeaderCell(langService.studentIssuingAuthority, 135, 8),
        _buildHeaderCell(langService.studentUniversity, 145, 9),
        _buildHeaderCell(langService.studentDepartment, 125, 10),
        _buildHeaderCell(langService.studentYear, 95, 11),
        _buildHeaderCell(langService.studentHasOtherDegree, 115, 12),
        _buildHeaderCell(langService.studentEmail, 175, 13),
        _buildHeaderCell(langService.studentPhone, 125, 14),
        _buildHeaderCell(langService.studentTaxNumber, 115, 15),
        _buildHeaderCell(langService.studentFatherJob, 135, 16),
        _buildHeaderCell(langService.studentMotherJob, 135, 17),
        _buildHeaderCell(langService.studentParentAddress, 195, 18),
        _buildHeaderCell(langService.studentParentCity, 115, 19),
        _buildHeaderCell(langService.studentParentRegion, 125, 20),
        _buildHeaderCell(langService.studentParentPostal, 95, 21),
        _buildHeaderCell(langService.studentParentCountry, 115, 22),
        _buildHeaderCell(langService.studentParentPhone, 125, 23),
        _buildHeaderCell(langService.studentCreatedAt, 115, 24),
      ];

  Widget _buildHeaderCell(String title, double width, int index) => InkWell(
        onTap: () => _sortByColumn(index),
        child: Container(
          width: width,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(color: Color(0xFFF8F9FA)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_sortColumnIndex == index)
                Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: const Color(0xFF374151),
                ),
            ],
          ),
        ),
      );

  Widget _buildDataRow(
    Student student,
    double screenWidth,
    int index,
    LanguageService langService,
  ) =>
      Container(
        height: 56,
        decoration: BoxDecoration(
          color: index.isEven ? Colors.white : const Color(0xFFFAFAFA),
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: SizedBox(
          width: _calculateContentWidth(screenWidth),
          child: Row(
            children: _buildDataCells(student, screenWidth, langService),
          ),
        ),
      );

  List<Widget> _buildDataCells(
    Student student,
    double screenWidth,
    LanguageService langService,
  ) =>
      [
        _buildDataCell(student.id, 95, fontWeight: FontWeight.w500),
        _buildDataCell(student.name, 115, fontWeight: FontWeight.w500),
        _buildDataCell(student.familyName, 115, fontWeight: FontWeight.w500),
        _buildDataCell(student.fatherName, 115),
        _buildDataCell(student.motherName, 115),
        _buildDataCell(langService.formatDisplayDate(student.birthDate), 105),
        _buildDataCell(student.birthPlace, 125),
        _buildDataCell(student.idCardNumber, 115),
        _buildDataCell(student.issuingAuthority, 135),
        _buildDataCell(student.university, 145),
        _buildDataCell(student.department, 125),
        _buildDataCell(student.yearOfStudy, 95),
        _buildDataCell(
          student.hasOtherDegree
              ? langService.getString('student_detail.yes')
              : langService.getString('student_detail.no'),
          115,
        ),
        _buildDataCell(student.email, 175, color: Colors.blue),
        _buildDataCell(student.phone, 125),
        _buildDataCell(student.taxNumber, 115),
        _buildDataCell(student.fatherJob, 135),
        _buildDataCell(student.motherJob, 135),
        _buildDataCell(student.parentAddress, 195),
        _buildDataCell(student.parentCity, 115),
        _buildDataCell(student.parentRegion, 125),
        _buildDataCell(student.parentPostal, 95),
        _buildDataCell(student.parentCountry, 115),
        _buildDataCell(student.parentNumber, 125),
        _buildDataCell(langService.formatDisplayDate(student.createdAt), 115),
      ];

  Widget _buildDataCell(
    String text,
    double width, {
    Color? color,
    FontWeight? fontWeight,
  }) =>
      Container(
        width: width,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color ?? const Color(0xFF6B7280),
              fontWeight: fontWeight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );

  Widget _buildActionsRow(Student student, LanguageService langService) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.onView != null)
            _buildActionButton(
              icon: Icons.visibility,
              color: Colors.blue,
              tooltip: langService.getString('students.actions.view_details'),
              onTap: () => widget.onView!(student),
            ),
          if (widget.onView != null &&
              (widget.onEdit != null || widget.onDelete != null))
            const SizedBox(width: 8),
          if (widget.onEdit != null)
            _buildActionButton(
              icon: Icons.edit,
              color: Colors.orange,
              tooltip: langService.getString('students.actions.edit'),
              onTap: () => widget.onEdit!(student),
            ),
          if (widget.onEdit != null && widget.onDelete != null)
            const SizedBox(width: 8),
          if (widget.onDelete != null)
            _buildActionButton(
              icon: Icons.delete,
              color: Colors.red,
              tooltip: langService.getString('students.actions.delete'),
              onTap: () => widget.onDelete!(student),
            ),
        ],
      );

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
        ),
      );

  void _sortByColumn(int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
      _applySorting();
    });
  }

  void _applySorting() {
    _sortedStudents.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_sortColumnIndex) {
        case 0:
          aValue = a.id;
          bValue = b.id;
          break;
        case 1:
          aValue = a.name;
          bValue = b.name;
          break;
        case 2:
          aValue = a.familyName;
          bValue = b.familyName;
          break;
        case 3:
          aValue = a.fatherName;
          bValue = b.fatherName;
          break;
        case 4:
          aValue = a.motherName;
          bValue = b.motherName;
          break;
        case 5:
          aValue = a.birthDate;
          bValue = b.birthDate;
          break;
        default:
          aValue = a.id;
          bValue = b.id;
      }

      int compareResult;
      if (aValue is String && bValue is String) {
        compareResult = aValue.compareTo(bValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        compareResult = aValue.compareTo(bValue);
      } else {
        compareResult = aValue.toString().compareTo(bValue.toString());
      }

      return _sortAscending ? compareResult : -compareResult;
    });
  }
}
