import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../models/student.dart';

class ExcelService {
  static const String _fileName = 'students_export';

  static Future<void> exportStudentsToExcel(
    List<Student> students, {
    Map<String, String>? localizedHeaders,
    Map<String, String>? localizedTitles,
  }) async {
    if (students.isEmpty) {
      throw Exception('No students to export');
    }

    try {
      // Create a new Excel document
      final excel = Excel.createExcel();

      // Create new sheet first, then remove default
      final sheetObject =
          excel[localizedTitles?['students_data'] ?? 'Students Data'];

      // Delete the default Sheet1 after creating our sheet
      try {
        excel.delete('Sheet1');
      } catch (e) {
        // Sheet1 might not exist or already deleted, which is fine
      }

      // Define headers
      final headers = [
        localizedHeaders?['id'] ?? 'ID',
        localizedHeaders?['name'] ?? 'Name',
        localizedHeaders?['family_name'] ?? 'Family Name',
        localizedHeaders?['father_name'] ?? 'Father Name',
        localizedHeaders?['mother_name'] ?? 'Mother Name',
        localizedHeaders?['birth_date'] ?? 'Birth Date',
        localizedHeaders?['birth_place'] ?? 'Birth Place',
        localizedHeaders?['id_card_number'] ?? 'ID Card Number',
        localizedHeaders?['issuing_authority'] ?? 'Issuing Authority',
        localizedHeaders?['university'] ?? 'University',
        localizedHeaders?['department'] ?? 'Department',
        localizedHeaders?['year_of_study'] ?? 'Year of Study',
        localizedHeaders?['has_other_degree'] ?? 'Has Other Degree',
        localizedHeaders?['email'] ?? 'Email',
        localizedHeaders?['phone'] ?? 'Phone',
        localizedHeaders?['tax_number'] ?? 'Tax Number',
        localizedHeaders?['father_job'] ?? 'Father Job',
        localizedHeaders?['mother_job'] ?? 'Mother Job',
        localizedHeaders?['parent_address'] ?? 'Parent Address',
        localizedHeaders?['parent_city'] ?? 'Parent City',
        localizedHeaders?['parent_region'] ?? 'Parent Region',
        localizedHeaders?['parent_postal'] ?? 'Parent Postal',
        localizedHeaders?['parent_country'] ?? 'Parent Country',
        localizedHeaders?['created_at'] ?? 'Created At',
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
        final studentData = student.toExcelMap(
          yesText: localizedHeaders?['yes'],
          noText: localizedHeaders?['no'],
        );

        var columnIndex = 0;
        for (final header in headers) {
          final cell = sheetObject.cell(
            CellIndex.indexByColumnRow(
              columnIndex: columnIndex,
              rowIndex: rowIndex + 1,
            ),
          );

          // Map localized header back to English key for data lookup
          String englishKey = header;
          if (localizedHeaders != null) {
            // Find the English key that corresponds to this localized header
            for (final entry in localizedHeaders.entries) {
              if (entry.value == header) {
                // Convert the key to the format used in toExcelMap()
                switch (entry.key) {
                  case 'id':
                    englishKey = 'ID';
                    break;
                  case 'name':
                    englishKey = 'Name';
                    break;
                  case 'family_name':
                    englishKey = 'Family Name';
                    break;
                  case 'father_name':
                    englishKey = 'Father Name';
                    break;
                  case 'mother_name':
                    englishKey = 'Mother Name';
                    break;
                  case 'birth_date':
                    englishKey = 'Birth Date';
                    break;
                  case 'birth_place':
                    englishKey = 'Birth Place';
                    break;
                  case 'id_card_number':
                    englishKey = 'ID Card Number';
                    break;
                  case 'issuing_authority':
                    englishKey = 'Issuing Authority';
                    break;
                  case 'university':
                    englishKey = 'University';
                    break;
                  case 'department':
                    englishKey = 'Department';
                    break;
                  case 'year_of_study':
                    englishKey = 'Year of Study';
                    break;
                  case 'has_other_degree':
                    englishKey = 'Has Other Degree';
                    break;
                  case 'email':
                    englishKey = 'Email';
                    break;
                  case 'phone':
                    englishKey = 'Phone';
                    break;
                  case 'tax_number':
                    englishKey = 'Tax Number';
                    break;
                  case 'father_job':
                    englishKey = 'Father Job';
                    break;
                  case 'mother_job':
                    englishKey = 'Mother Job';
                    break;
                  case 'parent_address':
                    englishKey = 'Parent Address';
                    break;
                  case 'parent_city':
                    englishKey = 'Parent City';
                    break;
                  case 'parent_region':
                    englishKey = 'Parent Region';
                    break;
                  case 'parent_postal':
                    englishKey = 'Parent Postal';
                    break;
                  case 'parent_country':
                    englishKey = 'Parent Country';
                    break;

                  case 'created_at':
                    englishKey = 'Created At';
                    break;
                }
                break;
              }
            }
          }

          final value = studentData[englishKey];
          if (value != null && value.toString().isNotEmpty) {
            var cellValue = value.toString();

            // Format dates properly as text
            if (englishKey == 'Birth Date') {
              try {
                final dateTime = DateTime.parse(cellValue);
                cellValue = DateFormat('dd/MM/yyyy').format(dateTime);
              } catch (e) {
                // Keep original value if parsing fails
              }
            } else if (englishKey == 'Created At') {
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
        dialogTitle: localizedTitles?['save_excel_title'] ?? 'Save Excel File',
        fileName: localizedTitles?['students_export'] ?? 'students_export.xlsx',
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
    Map<String, String>? localizedHeaders,
    Map<String, String>? localizedTitles,
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
      final sheetObject = excel[localizedTitles?['filtered_students_data'] ??
          'Filtered Students Data'];

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
        localizedHeaders?['id'] ?? 'ID',
        localizedHeaders?['name'] ?? 'Name',
        localizedHeaders?['family_name'] ?? 'Family Name',
        localizedHeaders?['father_name'] ?? 'Father Name',
        localizedHeaders?['mother_name'] ?? 'Mother Name',
        localizedHeaders?['birth_date'] ?? 'Birth Date',
        localizedHeaders?['birth_place'] ?? 'Birth Place',
        localizedHeaders?['id_card_number'] ?? 'ID Card Number',
        localizedHeaders?['issuing_authority'] ?? 'Issuing Authority',
        localizedHeaders?['university'] ?? 'University',
        localizedHeaders?['department'] ?? 'Department',
        localizedHeaders?['year_of_study'] ?? 'Year of Study',
        localizedHeaders?['has_other_degree'] ?? 'Has Other Degree',
        localizedHeaders?['email'] ?? 'Email',
        localizedHeaders?['phone'] ?? 'Phone',
        localizedHeaders?['tax_number'] ?? 'Tax Number',
        localizedHeaders?['father_job'] ?? 'Father Job',
        localizedHeaders?['mother_job'] ?? 'Mother Job',
        localizedHeaders?['parent_address'] ?? 'Parent Address',
        localizedHeaders?['parent_city'] ?? 'Parent City',
        localizedHeaders?['parent_region'] ?? 'Parent Region',
        localizedHeaders?['parent_postal'] ?? 'Parent Postal',
        localizedHeaders?['parent_country'] ?? 'Parent Country',
        localizedHeaders?['created_at'] ?? 'Created At',
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
      // Add student data rows
      for (var rowIndex = 0; rowIndex < students.length; rowIndex++) {
        final student = students[rowIndex];
        final studentData = student.toExcelMap(
          yesText: localizedHeaders?['yes'],
          noText: localizedHeaders?['no'],
        );

        var columnIndex = 0;
        for (final header in headers) {
          final cell = sheetObject.cell(
            CellIndex.indexByColumnRow(
              columnIndex: columnIndex,
              rowIndex: startRow + rowIndex + 1,
            ),
          );

          // Map localized header back to English key for data lookup
          String englishKey = header;
          if (localizedHeaders != null) {
            // Find the English key that corresponds to this localized header
            for (final entry in localizedHeaders.entries) {
              if (entry.value == header) {
                // Convert the key to the format used in toExcelMap()
                switch (entry.key) {
                  case 'id':
                    englishKey = 'ID';
                    break;
                  case 'name':
                    englishKey = 'Name';
                    break;
                  case 'family_name':
                    englishKey = 'Family Name';
                    break;
                  case 'father_name':
                    englishKey = 'Father Name';
                    break;
                  case 'mother_name':
                    englishKey = 'Mother Name';
                    break;
                  case 'birth_date':
                    englishKey = 'Birth Date';
                    break;
                  case 'birth_place':
                    englishKey = 'Birth Place';
                    break;
                  case 'id_card_number':
                    englishKey = 'ID Card Number';
                    break;
                  case 'issuing_authority':
                    englishKey = 'Issuing Authority';
                    break;
                  case 'university':
                    englishKey = 'University';
                    break;
                  case 'department':
                    englishKey = 'Department';
                    break;
                  case 'year_of_study':
                    englishKey = 'Year of Study';
                    break;
                  case 'has_other_degree':
                    englishKey = 'Has Other Degree';
                    break;
                  case 'email':
                    englishKey = 'Email';
                    break;
                  case 'phone':
                    englishKey = 'Phone';
                    break;
                  case 'tax_number':
                    englishKey = 'Tax Number';
                    break;
                  case 'father_job':
                    englishKey = 'Father Job';
                    break;
                  case 'mother_job':
                    englishKey = 'Mother Job';
                    break;
                  case 'parent_address':
                    englishKey = 'Parent Address';
                    break;
                  case 'parent_city':
                    englishKey = 'Parent City';
                    break;
                  case 'parent_region':
                    englishKey = 'Parent Region';
                    break;
                  case 'parent_postal':
                    englishKey = 'Parent Postal';
                    break;
                  case 'parent_country':
                    englishKey = 'Parent Country';
                    break;

                  case 'created_at':
                    englishKey = 'Created At';
                    break;
                }
                break;
              }
            }
          }

          final value = studentData[englishKey];
          if (value != null && value.toString().isNotEmpty) {
            var cellValue = value.toString();

            // Format dates properly as text
            if (englishKey == 'Birth Date') {
              try {
                final dateTime = DateTime.parse(cellValue);
                cellValue = DateFormat('dd/MM/yyyy').format(dateTime);
              } catch (e) {
                // Keep original value if parsing fails
              }
            } else if (englishKey == 'Created At') {
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

  static Future<void> exportSummaryToExcel(
    Map<String, dynamic> statistics, {
    Map<String, String>? localizedTitles,
  }) async {
    try {
      final excel = Excel.createExcel();

      // Create summary sheet first, then remove default
      final summarySheet = excel['Summary'];

      // Delete the default Sheet1 after creating our sheet
      try {
        excel.delete('Sheet1');
      } catch (e) {
        // Sheet1 might not exist or already deleted
      }

      // Title
      final titleCell = summarySheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      );
      titleCell.value = TextCellValue(
          localizedTitles?['summary'] ?? 'Students Database Summary');
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
        '${localizedTitles?['total_students'] ?? 'Total Students'}: ${statistics['totalStudents']}',
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
      excel.save(
          fileName:
              localizedTitles?['students_summary'] ?? 'students_summary.xlsx');
    } catch (e) {
      throw Exception('Failed to export summary to Excel: $e');
    }
  }
}
