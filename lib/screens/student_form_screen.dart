import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student.dart';
import '../services/language_service.dart';
import '../services/student_service.dart';
import '../utils/desktop_constants.dart';
import '../utils/validators.dart';

class StudentFormScreen extends StatefulWidget {

  const StudentFormScreen({super.key, this.studentId});
  final String? studentId;

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentService = StudentService();

  bool _isLoading = false;
  bool _isSaving = false;
  Student? _existingStudent;

  // Text controllers
  final _nameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _idCardController = TextEditingController();
  final _issuingAuthorityController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _fatherJobController = TextEditingController();
  final _motherJobController = TextEditingController();
  final _parentAddressController = TextEditingController();
  final _parentCityController = TextEditingController();
  final _parentRegionController = TextEditingController();
  final _parentPostalController = TextEditingController();
  final _parentCountryController = TextEditingController();
  final _parentNumberController = TextEditingController();
  final _universityController = TextEditingController();

  DateTime? _selectedBirthDate;
  String? _selectedDepartment;
  String? _selectedYearOfStudy;
  bool _hasOtherDegree = false;

  // Dropdown options - will be populated with localized values
  List<String> _departments = [];
  List<String> _yearsOfStudy = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocalizedData();
    });
    if (widget.studentId != null) {
      _loadStudent();
    }
  }

  void _initializeLocalizedData() {
    final langService = Provider.of<LanguageService>(context, listen: false);

    // Initialize localized dropdown values
    _departments = [
      langService.getString('student_form.departments.computer_science'),
      langService.getString('student_form.departments.electrical_engineering'),
      langService.getString('student_form.departments.mechanical_engineering'),
      langService.getString('student_form.departments.civil_engineering'),
      langService.getString('student_form.departments.business_administration'),
      langService.getString('student_form.departments.medicine'),
      langService.getString('student_form.departments.law'),
      langService.getString('student_form.departments.other'),
    ];

    _yearsOfStudy = [
      langService.getString('student_form.years_of_study.first_year'),
      langService.getString('student_form.years_of_study.second_year'),
      langService.getString('student_form.years_of_study.third_year'),
      langService.getString('student_form.years_of_study.fourth_year'),
      langService.getString('student_form.years_of_study.fifth_year'),
      langService.getString('student_form.years_of_study.graduate'),
      langService.getString('student_form.years_of_study.postgraduate'),
    ];

    _parentCountryController.text =
        langService.getString('student_form.default_country');

    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _familyNameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _birthPlaceController.dispose();
    _idCardController.dispose();
    _issuingAuthorityController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _taxNumberController.dispose();
    _fatherJobController.dispose();
    _motherJobController.dispose();
    _parentAddressController.dispose();
    _parentCityController.dispose();
    _parentRegionController.dispose();
    _parentPostalController.dispose();
    _parentCountryController.dispose();
    _parentNumberController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  Future<void> _loadStudent() async {
    if (widget.studentId == null) return;

    setState(() => _isLoading = true);

    try {
      final student = await _studentService.getStudentById(widget.studentId!);
      if (student != null) {
        _populateForm(student);
        _existingStudent = student;
      }
    } catch (e) {
      if (mounted) {
        final langService =
            Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(langService.getString('student_form.error_loading',
                params: {'error': e.toString()},),),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateForm(Student student) {
    _nameController.text = student.name;
    _familyNameController.text = student.familyName;
    _fatherNameController.text = student.fatherName;
    _motherNameController.text = student.motherName;
    _birthPlaceController.text = student.birthPlace;
    _idCardController.text = student.idCardNumber;
    _issuingAuthorityController.text = student.issuingAuthority;
    _emailController.text = student.email;
    _phoneController.text = student.phone;
    _taxNumberController.text = student.taxNumber;
    _fatherJobController.text = student.fatherJob;
    _motherJobController.text = student.motherJob;
    _parentAddressController.text = student.parentAddress;
    _parentCityController.text = student.parentCity;
    _parentRegionController.text = student.parentRegion;
    _parentPostalController.text = student.parentPostal;
    _parentCountryController.text = student.parentCountry;
    _parentNumberController.text = student.parentNumber;

    _selectedBirthDate = student.birthDate;
    _universityController.text = student.university;
    _selectedDepartment = student.department;
    _selectedYearOfStudy = student.yearOfStudy;
    _hasOtherDegree = student.hasOtherDegree;
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      final langService = Provider.of<LanguageService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(langService.getString('forms.select_birth_date')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.studentId != null) {
        // Update existing student
        final student = Student(
          id: widget.studentId!,
          name: _nameController.text.trim(),
          familyName: _familyNameController.text.trim(),
          fatherName: _fatherNameController.text.trim(),
          motherName: _motherNameController.text.trim(),
          birthDate: _selectedBirthDate!,
          birthPlace: _birthPlaceController.text.trim(),
          idCardNumber: _idCardController.text.trim(),
          issuingAuthority: _issuingAuthorityController.text.trim(),
          university: _universityController.text.trim(),
          department: _selectedDepartment ?? '',
          yearOfStudy: _selectedYearOfStudy ?? '',
          hasOtherDegree: _hasOtherDegree,
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          taxNumber: _taxNumberController.text.trim(),
          fatherJob: _fatherJobController.text.trim(),
          motherJob: _motherJobController.text.trim(),
          parentAddress: _parentAddressController.text.trim(),
          parentCity: _parentCityController.text.trim(),
          parentRegion: _parentRegionController.text.trim(),
          parentPostal: _parentPostalController.text.trim(),
          parentCountry: _parentCountryController.text.trim(),
          parentNumber: _parentNumberController.text.trim(),
          createdAt: _existingStudent!.createdAt,
        );
        await _studentService.updateStudent(student);
      } else {
        // Create new student - let database generate ID
        final studentData = {
          'name': _nameController.text.trim(),
          'family_name': _familyNameController.text.trim(),
          'father_name': _fatherNameController.text.trim(),
          'mother_name': _motherNameController.text.trim(),
          'birth_date': _selectedBirthDate!.toIso8601String().split('T')[0],
          'birth_place': _birthPlaceController.text.trim(),
          'id_card_number': _idCardController.text.trim(),
          'issuing_authority': _issuingAuthorityController.text.trim(),
          'university': _universityController.text.trim(),
          'department': _selectedDepartment ?? '',
          'year_of_study': _selectedYearOfStudy ?? '',
          'has_other_degree': _hasOtherDegree,
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'tax_number': _taxNumberController.text.trim(),
          'father_job': _fatherJobController.text.trim(),
          'mother_job': _motherJobController.text.trim(),
          'parent_address': _parentAddressController.text.trim(),
          'parent_city': _parentCityController.text.trim(),
          'parent_region': _parentRegionController.text.trim(),
          'parent_postal': _parentPostalController.text.trim(),
          'parent_country': _parentCountryController.text.trim(),
          'parent_number': _parentNumberController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        };
        await _studentService.createStudentFromData(studentData);
      }

      if (mounted) {
        final langService =
            Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.studentId != null
                ? langService.getString('student_form.student_updated')
                : langService.getString('student_form.student_saved'),),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final langService =
            Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(langService.getString('student_form.error_saving',
                params: {'error': e.toString()},),),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<LanguageService>(
      builder: (context, langService, child) {
        if (_isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text(langService.getString('common.loading')),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.studentId != null
                  ? langService.getString('students.edit_student')
                  : langService.getString('students.add_student'),
            ),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : _saveStudent,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        langService.getString('buttons.save'),
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPersonalInfoSection(langService),
                  const SizedBox(height: 24),
                  _buildEducationSection(langService),
                  const SizedBox(height: 24),
                  _buildContactSection(langService),
                  const SizedBox(height: 24),
                  _buildParentInfoSection(langService),
                  const SizedBox(height: 32),
                  _buildActionButtons(langService),
                ],
              ),
            ),
          ),
        );
      },
    );

  Widget _buildPersonalInfoSection(LanguageService langService) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        Validators.required(value, 'First name'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _familyNameController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        Validators.required(value, 'Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fatherNameController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Father Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        Validators.required(value, 'Father name'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _motherNameController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Mother Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        Validators.required(value, 'Mother name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Birth Date *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _selectedBirthDate != null
                            ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                            : 'Select date',
                        style: TextStyle(
                          color: _selectedBirthDate != null
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _birthPlaceController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Birth Place *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        Validators.required(value, 'Birth place'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _idCardController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'ID Card Number *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        Validators.required(value, 'ID card number'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _issuingAuthorityController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Issuing Authority *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        Validators.required(value, 'Issuing authority'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildEducationSection(LanguageService langService) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Education Information',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _universityController,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'University *',
                border: OutlineInputBorder(),
                hintText: 'Enter university name',
              ),
              validator: (value) => Validators.required(value, 'University'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: 'Department *',
                      border: OutlineInputBorder(),
                    ),
                    items: _departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedDepartment = value),
                    validator: (value) =>
                        value == null ? 'Please select a department' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedYearOfStudy,
                    decoration: const InputDecoration(
                      labelText: 'Year of Study *',
                      border: OutlineInputBorder(),
                    ),
                    items: _yearsOfStudy.map((year) => DropdownMenuItem(value: year, child: Text(year))).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedYearOfStudy = value),
                    validator: (value) =>
                        value == null ? 'Please select year of study' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Has Other Degree'),
              value: _hasOtherDegree,
              onChanged: (value) =>
                  setState(() => _hasOtherDegree = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );

  Widget _buildContactSection(LanguageService langService) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Phone *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: Validators.phone,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _taxNumberController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Tax Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildParentInfoSection(LanguageService langService) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parent Information',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fatherJobController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Father Job',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _motherJobController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Mother Job',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _parentAddressController,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _parentCityController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _parentRegionController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Region',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _parentPostalController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Postal Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _parentCountryController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _parentNumberController,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Parent Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );

  Widget _buildActionButtons(LanguageService langService) => Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(langService.getString('buttons.cancel')),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveStudent,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(langService.getString('buttons.save')),
        ),
      ],
    );

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ??
          DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() => _selectedBirthDate = picked);
    }
  }
}
