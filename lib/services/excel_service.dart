import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/student.dart';

class ExcelService {
  static const String _fileName = 'students_export';

  static Future<void> exportStudentsToExcel(List<Student> students) async {
    if (students.isEmpty) {
      throw Exception('No students to export');
    }

    try {
      // Create a new Excel document
      final excel = Excel.createExcel();

      // Create new sheet first, then remove default
      final sheetObject = excel['Students Data'];

      // Delete the default Sheet1 after creating our sheet
      try {
        excel.delete('Sheet1');
      } catch (e) {
        // Sheet1 might not exist or already deleted, which is fine
      }

      // Define headers
      final headers = [
        'ID',
        'Name',
        'Family Name',
        'Father Name',
        'Mother Name',
        'Birth Date',
        'Birth Place',
        'ID Card Number',
        'Issuing Authority',
        'University',
        'Department',
        'Year of Study',
        'Has Other Degree',
        'Email',
        'Phone',
        'Tax Number',
        'Father Job',
        'Mother Job',
        'Parent Address',
        'Parent City',
        'Parent Region',
        'Parent Postal',
        'Parent Country',
        'Parent Number',
        'Created At',
      ];

      // Add headers to the first row
      for (var i = 0; i < headers.length; i++) {
        final cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);

        // Style the header
        cell.cellStyle = CellStyle(bold: true, fontSize: 12);
      }

      // Add student data
      for (var rowIndex = 0; rowIndex < students.length; rowIndex++) {
        final student = students[rowIndex];
        final studentData = student.toExcelMap();

        var columnIndex = 0;
        for (final header in headers) {
          final cell = sheetObject.cell(
            CellIndex.indexByColumnRow(
              columnIndex: columnIndex,
              rowIndex: rowIndex + 1,
            ),
          );

          final value = studentData[header];
          if (value != null && value.toString().isNotEmpty) {
            var cellValue = value.toString();

            // Format dates properly as text
            if (header == 'Birth Date') {
              try {
                final dateTime = DateTime.parse(cellValue);
                cellValue = DateFormat('dd/MM/yyyy').format(dateTime);
              } catch (e) {
                // Keep original value if parsing fails
              }
            } else if (header == 'Created At') {
              try {
                final dateTime = DateTime.parse(cellValue);
                cellValue = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
              } catch (e) {
                // Keep original value if parsing fails
              }
            }

            cell.value = TextCellValue(cellValue);
          } else {
            cell.value = TextCellValue('');
          }

          // Apply row styling
          cell.cellStyle = CellStyle(fontSize: 11);

          columnIndex++;
        }
      }

      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheetObject.setColumnAutoFit(i);
      }

      // Generate and download Excel file
      final excelBytes = excel.encode();
      final excelUint8List =
          excelBytes != null ? Uint8List.fromList(excelBytes) : null;

      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel File',
        fileName: 'students_export.xlsx',
        bytes: excelUint8List,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(excelBytes!);
      }
    } catch (e) {
      throw Exception('Failed to export to Excel: $e');
    }
  }

  static Future<void> exportFilteredStudentsToExcel(
    List<Student> students, {
    String? searchQuery,
    String? university,
    String? department,
    String? yearOfStudy,
  }) async {
    if (students.isEmpty) {
      throw Exception('No students to export');
    }

    try {
      // Create filename with filters
      var fileName = _fileName;
      final filters = <String>[];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        filters.add('search_${searchQuery.replaceAll(' ', '_')}');
      }
      if (university != null && university.isNotEmpty) {
        filters.add('uni_${university.replaceAll(' ', '_')}');
      }
      if (department != null && department.isNotEmpty) {
        filters.add('dept_${department.replaceAll(' ', '_')}');
      }
      if (yearOfStudy != null && yearOfStudy.isNotEmpty) {
        filters.add('year_$yearOfStudy');
      }

      if (filters.isNotEmpty) {
        fileName += '_${filters.join('_')}';
      }

      // Create Excel document
      final excel = Excel.createExcel();

      // Create new sheet first, then remove default
      final sheetObject = excel['Filtered Students Data'];

      // Delete the default Sheet1 after creating our sheet
      try {
        excel.delete('Sheet1');
      } catch (e) {
        // Sheet1 might not exist or already deleted, which is fine
      }

      // Add filter information at the top
      if (filters.isNotEmpty) {
        final filterCell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        );
        filterCell.value = TextCellValue('Applied Filters:');
        filterCell.cellStyle = CellStyle(bold: true, fontSize: 14);

        var filterRow = 1;
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filterRow),
          );
          cell.value = TextCellValue('Search: $searchQuery');
          filterRow++;
        }
        if (university != null && university.isNotEmpty) {
          final cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filterRow),
          );
          cell.value = TextCellValue('University: $university');
          filterRow++;
        }
        if (department != null && department.isNotEmpty) {
          final cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filterRow),
          );
          cell.value = TextCellValue('Department: $department');
          filterRow++;
        }
        if (yearOfStudy != null && yearOfStudy.isNotEmpty) {
          final cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filterRow),
          );
          cell.value = TextCellValue('Year of Study: $yearOfStudy');
          filterRow++;
        }

        // Add empty row
        filterRow++;
      }

      // Define headers
      final headers = [
        'ID',
        'Name',
        'Family Name',
        'Father Name',
        'Mother Name',
        'Birth Date',
        'Birth Place',
        'ID Card Number',
        'Issuing Authority',
        'University',
        'Department',
        'Year of Study',
        'Has Other Degree',
        'Email',
        'Phone',
        'Tax Number',
        'Father Job',
        'Mother Job',
        'Parent Address',
        'Parent City',
        'Parent Region',
        'Parent Postal',
        'Parent Country',
        'Parent Number',
        'Created At',
      ];

      final startRow = filters.isNotEmpty ? 6 : 0;

      // Add headers
      for (var i = 0; i < headers.length; i++) {
        final cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(bold: true, fontSize: 12);
      }

      // Add student data
      for (var rowIndex = 0; rowIndex < students.length; rowIndex++) {
        final student = students[rowIndex];
        final studentData = student.toExcelMap();

        var columnIndex = 0;
        for (final header in headers) {
          final cell = sheetObject.cell(
            CellIndex.indexByColumnRow(
              columnIndex: columnIndex,
              rowIndex: startRow + rowIndex + 1,
            ),
          );

          final value = studentData[header];
          if (value != null && value.toString().isNotEmpty) {
            var cellValue = value.toString();

            // Format dates properly as text
            if (header == 'Birth Date') {
              try {
                final dateTime = DateTime.parse(cellValue);
                cellValue = DateFormat('dd/MM/yyyy').format(dateTime);
              } catch (e) {
                // Keep original value if parsing fails
              }
            } else if (header == 'Created At') {
              try {
                final dateTime = DateTime.parse(cellValue);
                cellValue = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
              } catch (e) {
                // Keep original value if parsing fails
              }
            }

            cell.value = TextCellValue(cellValue);
          } else {
            cell.value = TextCellValue('');
          }

          // Apply row styling
          cell.cellStyle = CellStyle(fontSize: 11);

          columnIndex++;
        }
      }

      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheetObject.setColumnAutoFit(i);
      }

      // Generate and download filtered Excel file
      excel.save(fileName: '$fileName.xlsx');
    } catch (e) {
      throw Exception('Failed to export filtered data to Excel: $e');
    }
  }

  static Future<void> exportStudentsSummaryToExcel(
    Map<String, dynamic> statistics,
  ) async {
    try {
      final excel = Excel.createExcel();

      // Create summary sheet first, then remove default
      final summarySheet = excel['Summary'];

      // Delete the default Sheet1 after creating our sheet
      try {
        excel.delete('Sheet1');
      } catch (e) {
        // Sheet1 might not exist or already deleted
        debugPrint('Note: Could not delete Sheet1: $e');
      }

      // Title
      final titleCell = summarySheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      );
      titleCell.value = TextCellValue('Students Database Summary');
      titleCell.cellStyle = CellStyle(bold: true, fontSize: 16);

      // Generation date
      final dateCell = summarySheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      );
      dateCell.value = TextCellValue(
        'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
      );
      dateCell.cellStyle = CellStyle(fontSize: 12);

      // Total students
      final totalCell = summarySheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3),
      );
      totalCell.value = TextCellValue(
        'Total Students: ${statistics['totalStudents']}',
      );
      totalCell.cellStyle = CellStyle(bold: true, fontSize: 14);

      var currentRow = 5;

      // University distribution
      final uniHeaderCell = summarySheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      uniHeaderCell.value = TextCellValue('Students by University:');
      uniHeaderCell.cellStyle = CellStyle(bold: true, fontSize: 12);
      currentRow++;

      final universityCounts =
          statistics['universityCounts'] as Map<String, int>;
      for (final entry in universityCounts.entries) {
        final cell = summarySheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
        );
        cell.value = TextCellValue('${entry.key}: ${entry.value}');
        currentRow++;
      }

      currentRow++;

      // Department distribution
      final deptHeaderCell = summarySheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      deptHeaderCell.value = TextCellValue('Students by Department:');
      deptHeaderCell.cellStyle = CellStyle(bold: true, fontSize: 12);
      currentRow++;

      final departmentCounts =
          statistics['departmentCounts'] as Map<String, int>;
      for (final entry in departmentCounts.entries) {
        final cell = summarySheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
        );
        cell.value = TextCellValue('${entry.key}: ${entry.value}');
        currentRow++;
      }

      currentRow++;

      // Year distribution
      final yearHeaderCell = summarySheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      yearHeaderCell.value = TextCellValue('Students by Year of Study:');
      yearHeaderCell.cellStyle = CellStyle(bold: true, fontSize: 12);
      currentRow++;

      final yearCounts = statistics['yearCounts'] as Map<String, int>;
      for (final entry in yearCounts.entries) {
        final cell = summarySheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
        );
        cell.value = TextCellValue('${entry.key}: ${entry.value}');
        currentRow++;
      }

      // Auto-fit columns
      summarySheet.setColumnAutoFit(0);
      summarySheet.setColumnAutoFit(1);

      // Generate and download summary Excel file
      excel.save(fileName: 'students_summary.xlsx');
      debugPrint('Summary Excel file downloaded successfully');
    } catch (e) {
      throw Exception('Failed to export summary to Excel: $e');
    }
  }
}
