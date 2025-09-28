import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/student.dart';
import '../models/student_receipt.dart';
import '../providers/receipt_provider.dart';

import '../services/language_service.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Upload form state
  int? _selectedMonth;
  int? _selectedYear;
  PlatformFile? _selectedFile;
  final _formKey = GlobalKey<FormState>();

  // Panel state
  int _currentPanel = 0; // 0: Students, 1: Receipts, 2: Upload

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceiptProvider>().loadStudents();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<ReceiptProvider>().searchStudents(_searchController.text);
  }

  void _selectStudent(Student student) {
    context.read<ReceiptProvider>().selectStudent(student);
    context.read<ReceiptProvider>().loadReceipts();
    setState(() {
      _currentPanel = 1;
    });
  }

  void _showUploadForm() {
    setState(() {
      _currentPanel = 2;
      _selectedMonth = null;
      _selectedYear = null;
      _selectedFile = null;
    });
  }

  void _goBackToStudents() {
    context.read<ReceiptProvider>().clearSelectedStudent();
    setState(() {
      _currentPanel = 0;
    });
  }

  void _goBackToReceipts() {
    setState(() {
      _currentPanel = 1;
      _selectedMonth = null;
      _selectedYear = null;
      _selectedFile = null;
    });
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedFile = result.files.single;
        });
      }
    } catch (e) {
      if (mounted) {
        final langService = context.read<LanguageService>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              langService.getString('receipts.forms.invalid_file'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadReceipt() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) return;

    final receiptProvider = context.read<ReceiptProvider>();
    final selectedStudent = receiptProvider.selectedStudent;
    if (selectedStudent == null) return;

    final success = await receiptProvider.uploadReceipt(
      studentId: selectedStudent.id,
      file: _selectedFile!,
      concernsMonth: _selectedMonth!,
      concernsYear: _selectedYear!,
    );

    if (mounted) {
      final langService = context.read<LanguageService>();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              langService.getString('receipts.upload_success'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        _goBackToReceipts();
      } else {
        final error = receiptProvider.error ??
            langService.getString('errors.unknown_error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error == 'receipt_exists'
                  ? langService.getString('receipts.errors.receipt_exists')
                  : langService.getString('receipts.upload_error',
                      params: {'error': error}),
            ),
            backgroundColor:
                error == 'receipt_exists' ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteReceipt(StudentReceipt receipt) async {
    final langService = context.read<LanguageService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(langService.getString('receipts.delete_receipt')),
        content: Text(langService.getString('receipts.delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(langService.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(langService.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await context.read<ReceiptProvider>().deleteReceipt(receipt.id);
      if (mounted) {
        final langService = context.read<LanguageService>();
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(langService.getString('receipts.delete_success')),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final error = context.read<ReceiptProvider>().error ??
              langService.getString('errors.unknown_error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                langService.getString('receipts.delete_error',
                    params: {'error': error}),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Consumer2<LanguageService, ReceiptProvider>(
      builder: (context, langService, receiptProvider, child) {
        String title;
        switch (_currentPanel) {
          case 0:
            title = langService.getString('receipts.title');
            break;
          case 1:
            title = langService.getString('receipts.student_receipts');
            break;
          case 2:
            title = langService.getString('receipts.upload_new_receipt');
            break;
          default:
            title = langService.getString('receipts.title');
        }

        if (isMobile) {
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              leading: _currentPanel > 0
                  ? IconButton(
                      onPressed: _currentPanel == 1
                          ? _goBackToStudents
                          : _goBackToReceipts,
                      icon: const Icon(Icons.arrow_back),
                    )
                  : null,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 2,
            ),
            body: _buildContent(langService, receiptProvider),
          );
        } else {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_currentPanel > 0) ...[
                      IconButton(
                        onPressed: _currentPanel == 1
                            ? _goBackToStudents
                            : _goBackToReceipts,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (_currentPanel > 0 &&
                              receiptProvider.selectedStudent != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              receiptProvider.selectedStudent!.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildContent(langService, receiptProvider),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildContent(
      LanguageService langService, ReceiptProvider receiptProvider) {
    switch (_currentPanel) {
      case 0:
        return _buildStudentsPanel(langService, receiptProvider);
      case 1:
        return _buildReceiptsPanel(langService, receiptProvider);
      case 2:
        return _buildUploadPanel(langService, receiptProvider);
      default:
        return _buildStudentsPanel(langService, receiptProvider);
    }
  }

  Widget _buildStudentsPanel(
      LanguageService langService, ReceiptProvider receiptProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: langService.getString('receipts.search_placeholder'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),
        Expanded(
          child: receiptProvider.isLoadingStudents
              ? const Center(child: CircularProgressIndicator())
              : receiptProvider.filteredStudents.isEmpty
                  ? Center(
                      child: Text(
                        langService.getString('receipts.no_students'),
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: receiptProvider.filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = receiptProvider.filteredStudents[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              radius: 24,
                              child: Text(
                                student.name.isNotEmpty
                                    ? student.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            title: Text(
                              student.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  student.email,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if (student.university?.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      student.university!,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 20),
                            onTap: () => _selectStudent(student),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildReceiptsPanel(
      LanguageService langService, ReceiptProvider receiptProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  langService.getString('receipts.view_receipts'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showUploadForm,
                icon: const Icon(Icons.add),
                label: Text(langService.getString('receipts.upload_receipt')),
              ),
            ],
          ),
        ),
        Expanded(
          child: receiptProvider.isLoadingReceipts
              ? const Center(child: CircularProgressIndicator())
              : receiptProvider.receipts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            langService.getString('receipts.no_receipts'),
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showUploadForm,
                            icon: const Icon(Icons.add),
                            label: Text(langService
                                .getString('receipts.upload_receipt')),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: receiptProvider.receipts.length,
                      itemBuilder: (context, index) {
                        final receipt = receiptProvider.receipts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Icon(
                              Icons.receipt,
                              color: Colors.blue,
                              size: 28,
                            ),
                            title: Text(
                              receipt.periodDescription,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  receipt.originalFileName,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.folder_open,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      receipt.fileSizeFormatted,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    if (receipt.uploadedAt != null) ...[
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          langService.formatDisplayDate(
                                              receipt.uploadedAt!),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onSelected: (value) {
                                switch (value) {
                                  case 'view':
                                    _viewReceipt(receipt);
                                    break;
                                  case 'delete':
                                    _deleteReceipt(receipt);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.visibility, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        langService
                                            .getString('receipts.view_receipt'),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        langService.getString(
                                            'receipts.delete_receipt'),
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUploadPanel(
      LanguageService langService, ReceiptProvider receiptProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              langService.getString('receipts.select_month'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedMonth,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (value) {
                if (value == null) {
                  return langService.getString('receipts.forms.select_month');
                }
                return null;
              },
              items: List.generate(12, (index) {
                final month = index + 1;
                final monthName = langService
                    .getString('receipts.months.${_getMonthKey(month)}');
                return DropdownMenuItem(
                  value: month,
                  child: Text(
                    monthName,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }),
              onChanged: (value) {
                setState(() {
                  _selectedMonth = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              langService.getString('receipts.select_year'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedYear,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (value) {
                if (value == null) {
                  return langService.getString('receipts.forms.select_year');
                }
                return null;
              },
              items: List.generate(10, (index) {
                final year = DateTime.now().year - index;
                return DropdownMenuItem(
                  value: year,
                  child: Text(
                    year.toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }),
              onChanged: (value) {
                setState(() {
                  _selectedYear = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              langService.getString('receipts.choose_file'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile != null
                          ? langService.getString('receipts.file_selected',
                              params: {'filename': _selectedFile!.name})
                          : langService.getString('receipts.no_file_selected'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedFile != null
                            ? Colors.green
                            : Colors.grey[600],
                        fontWeight: _selectedFile != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        receiptProvider.isUploading ? null : _goBackToReceipts,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      langService.cancel,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        receiptProvider.isUploading ? null : _uploadReceipt,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: receiptProvider.isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            langService.getString('receipts.upload'),
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthKey(int month) {
    const monthKeys = [
      '',
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    return month >= 1 && month <= 12 ? monthKeys[month] : '';
  }

  Future<void> _viewReceipt(StudentReceipt receipt) async {
    final url = await context
        .read<ReceiptProvider>()
        .getReceiptViewUrl(receipt.filePath);
    if (url != null && mounted) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: show URL in dialog if can't launch
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(receipt.originalFileName),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${context.read<LanguageService>().getString('receipts.receipt_period')}: ${receipt.periodDescription}'),
                  Text(
                      '${context.read<LanguageService>().getString('receipts.file_size')}: ${receipt.fileSizeFormatted}'),
                  if (receipt.uploadedAt != null)
                    Text(
                        '${context.read<LanguageService>().getString('receipts.uploaded_at')}: ${context.read<LanguageService>().formatDisplayDate(receipt.uploadedAt!)}'),
                  const SizedBox(height: 16),
                  Text(context
                      .read<LanguageService>()
                      .getString('receipts.view_receipt')),
                  const SizedBox(height: 8),
                  SelectableText(url),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                      context.read<LanguageService>().getString('app.close')),
                ),
              ],
            ),
          );
        }
      }
    } else if (mounted) {
      final error = context.read<ReceiptProvider>().error ??
          context
              .read<LanguageService>()
              .getString('errors.failed_to_get_receipt_url');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${context.read<LanguageService>().getString('receipts.view_receipt')}: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
