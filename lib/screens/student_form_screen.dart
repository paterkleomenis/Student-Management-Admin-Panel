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
  late Student? _existingStudent;

  // Text controllers
  late final _nameController = TextEditingController();
  late final _familyNameController = TextEditingController();
  late final _fatherNameController = TextEditingController();
  late final _motherNameController = TextEditingController();
  late final _birthPlaceController = TextEditingController();
  late final _idCardController = TextEditingController();
  late final _issuingAuthorityController = TextEditingController();
  late final _emailController = TextEditingController();
  late final _phoneController = TextEditingController();
  late final _passwordController = TextEditingController();
  late final _taxNumberController = TextEditingController();
  late final _fatherJobController = TextEditingController();
  late final _motherJobController = TextEditingController();
  late final _parentAddressController = TextEditingController();
  late final _parentCityController = TextEditingController();
  late final _parentRegionController = TextEditingController();
  late final _parentPostalController = TextEditingController();
  late final _parentCountryController = TextEditingController();

  late final _universityController = TextEditingController();
  late final _departmentController = TextEditingController();

  DateTime? _selectedBirthDate;
  String? _selectedYearOfStudy;
  bool _hasOtherDegree = false;

  // Dropdown options - will be populated with localized values
  List<String>? _yearsOfStudy;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _existingStudent = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocalizedData();
      if (widget.studentId != null) {
        _loadStudent();
      }
    });
  }

  void _initializeLocalizedData() {
    final langService = Provider.of<LanguageService>(context, listen: false);

    // Initialize localized dropdown values
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

  String? _mapDatabaseValueToLocalizedYear(String? databaseValue) {
    if (databaseValue == null || databaseValue.isEmpty) return null;

    final langService = Provider.of<LanguageService>(context, listen: false);

    // Map database values to localized strings
    switch (databaseValue.toLowerCase()) {
      case '1':
      case 'first':
      case 'first_year':
        return langService.getString('student_form.years_of_study.first_year');
      case '2':
      case 'second':
      case 'second_year':
        return langService.getString('student_form.years_of_study.second_year');
      case '3':
      case 'third':
      case 'third_year':
        return langService.getString('student_form.years_of_study.third_year');
      case '4':
      case 'fourth':
      case 'fourth_year':
        return langService.getString('student_form.years_of_study.fourth_year');
      case '5':
      case 'fifth':
      case 'fifth_year':
        return langService.getString('student_form.years_of_study.fifth_year');
      case 'graduate':
        return langService.getString('student_form.years_of_study.graduate');
      case 'postgraduate':
        return langService
            .getString('student_form.years_of_study.postgraduate');
      default:
        // If the value already matches one of our localized strings, return it
        if (_yearsOfStudy?.contains(databaseValue) ?? false) {
          return databaseValue;
        }
        // Otherwise, return null to avoid the dropdown error
        return null;
    }
  }

  String? _mapLocalizedYearToDatabaseValue(String? localizedValue) {
    if (localizedValue == null) return null;

    final langService = Provider.of<LanguageService>(context, listen: false);

    // Map localized strings back to database values
    if (localizedValue ==
        langService.getString('student_form.years_of_study.first_year')) {
      return '1';
    } else if (localizedValue ==
        langService.getString('student_form.years_of_study.second_year')) {
      return '2';
    } else if (localizedValue ==
        langService.getString('student_form.years_of_study.third_year')) {
      return '3';
    } else if (localizedValue ==
        langService.getString('student_form.years_of_study.fourth_year')) {
      return '4';
    } else if (localizedValue ==
        langService.getString('student_form.years_of_study.fifth_year')) {
      return '5';
    } else if (localizedValue ==
        langService.getString('student_form.years_of_study.graduate')) {
      return 'graduate';
    } else if (localizedValue ==
        langService.getString('student_form.years_of_study.postgraduate')) {
      return 'postgraduate';
    }

    return localizedValue; // Fallback to original value
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
    _passwordController.dispose();
    _taxNumberController.dispose();
    _fatherJobController.dispose();
    _motherJobController.dispose();
    _parentAddressController.dispose();
    _parentCityController.dispose();
    _parentRegionController.dispose();
    _parentPostalController.dispose();
    _parentCountryController.dispose();

    _universityController.dispose();
    _departmentController.dispose();
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
            content: Text(
              langService.getString(
                'student_form.error_loading',
                params: {'error': e.toString()},
              ),
            ),
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
    _fatherNameController.text = student.fatherName ?? '';
    _motherNameController.text = student.motherName ?? '';
    _birthPlaceController.text = student.birthPlace;
    _idCardController.text = student.idCardNumber ?? '';
    _issuingAuthorityController.text = student.issuingAuthority ?? '';
    _universityController.text = student.university ?? '';
    _phoneController.text = student.phone ?? '';
    _taxNumberController.text = student.taxNumber ?? '';
    _fatherJobController.text = student.fatherJob ?? '';
    _motherJobController.text = student.motherJob ?? '';
    _parentAddressController.text = student.parentAddress ?? '';
    _parentCityController.text = student.parentCity ?? '';
    _parentRegionController.text = student.parentRegion ?? '';
    _parentPostalController.text = student.parentPostal ?? '';
    _parentCountryController.text = student.parentCountry ?? '';

    _emailController.text = student.email;
    _selectedBirthDate = student.birthDate;
    _universityController.text = student.university ?? '';
    _departmentController.text = student.department ?? '';
    _selectedYearOfStudy =
        _mapDatabaseValueToLocalizedYear(student.yearOfStudy);
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

    // Check birth place is not empty since it's required
    if (_birthPlaceController.text.trim().isEmpty) {
      final langService = Provider.of<LanguageService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            langService.getString('student_form.validators.birth_place'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check password is not empty for new students only
    if (widget.studentId == null && _passwordController.text.trim().isEmpty) {
      final langService = Provider.of<LanguageService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            langService.getString('student_form.validators.password'),
          ),
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
          id: _existingStudent!.id,
          name: _nameController.text.trim(),
          familyName: _familyNameController.text.trim(),
          fatherName: _fatherNameController.text.trim().isEmpty
              ? null
              : _fatherNameController.text.trim(),
          motherName: _motherNameController.text.trim().isEmpty
              ? null
              : _motherNameController.text.trim(),
          birthDate: _selectedBirthDate,
          birthPlace: _birthPlaceController.text.trim(),
          idCardNumber: _idCardController.text.trim().isEmpty
              ? null
              : _idCardController.text.trim(),
          issuingAuthority: _issuingAuthorityController.text.trim().isEmpty
              ? null
              : _issuingAuthorityController.text.trim(),
          university: _universityController.text.trim().isEmpty
              ? null
              : _universityController.text.trim(),
          department: _departmentController.text.trim().isEmpty
              ? null
              : _departmentController.text.trim(),
          yearOfStudy: _mapLocalizedYearToDatabaseValue(_selectedYearOfStudy),
          hasOtherDegree: _hasOtherDegree,
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          taxNumber: _taxNumberController.text.trim().isEmpty
              ? null
              : _taxNumberController.text.trim(),
          fatherJob: _fatherJobController.text.trim().isEmpty
              ? null
              : _fatherJobController.text.trim(),
          motherJob: _motherJobController.text.trim().isEmpty
              ? null
              : _motherJobController.text.trim(),
          parentAddress: _parentAddressController.text.trim().isEmpty
              ? null
              : _parentAddressController.text.trim(),
          parentCity: _parentCityController.text.trim().isEmpty
              ? null
              : _parentCityController.text.trim(),
          parentRegion: _parentRegionController.text.trim().isEmpty
              ? null
              : _parentRegionController.text.trim(),
          parentPostal: _parentPostalController.text.trim().isEmpty
              ? null
              : _parentPostalController.text.trim(),
          parentCountry: _parentCountryController.text.trim().isEmpty
              ? null
              : _parentCountryController.text.trim(),
          createdAt: _existingStudent!.createdAt,
        );
        await _studentService.updateStudent(student);
      } else {
        // Create new student - let database generate ID
        final studentData = <String, dynamic>{
          'name': _nameController.text.trim(),
          'family_name': _familyNameController.text.trim(),
          'birth_date': _selectedBirthDate!.toIso8601String().split('T')[0],
          'birth_place': _birthPlaceController.text.trim(),
          'has_other_degree': _hasOtherDegree,
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        };

        // Add password only for new students
        if (widget.studentId == null) {
          studentData['password'] = _passwordController.text.trim();
        }

        // Only add non-empty optional fields
        if (_fatherNameController.text.trim().isNotEmpty) {
          studentData['father_name'] = _fatherNameController.text.trim();
        }
        if (_motherNameController.text.trim().isNotEmpty) {
          studentData['mother_name'] = _motherNameController.text.trim();
        }
        if (_idCardController.text.trim().isNotEmpty) {
          studentData['id_card_number'] = _idCardController.text.trim();
        }
        if (_issuingAuthorityController.text.trim().isNotEmpty) {
          studentData['issuing_authority'] =
              _issuingAuthorityController.text.trim();
        }
        if (_universityController.text.trim().isNotEmpty) {
          studentData['university'] = _universityController.text.trim();
        }
        if (_departmentController.text.trim().isNotEmpty) {
          studentData['department'] = _departmentController.text.trim();
        }
        final yearOfStudy =
            _mapLocalizedYearToDatabaseValue(_selectedYearOfStudy);
        if (yearOfStudy != null && yearOfStudy.isNotEmpty) {
          studentData['year_of_study'] = yearOfStudy;
        }
        if (_taxNumberController.text.trim().isNotEmpty) {
          studentData['tax_number'] = _taxNumberController.text.trim();
        }
        if (_fatherJobController.text.trim().isNotEmpty) {
          studentData['father_job'] = _fatherJobController.text.trim();
        }
        if (_motherJobController.text.trim().isNotEmpty) {
          studentData['mother_job'] = _motherJobController.text.trim();
        }
        if (_parentAddressController.text.trim().isNotEmpty) {
          studentData['parent_address'] = _parentAddressController.text.trim();
        }
        if (_parentCityController.text.trim().isNotEmpty) {
          studentData['parent_city'] = _parentCityController.text.trim();
        }
        if (_parentRegionController.text.trim().isNotEmpty) {
          studentData['parent_region'] = _parentRegionController.text.trim();
        }
        if (_parentPostalController.text.trim().isNotEmpty) {
          studentData['parent_postal'] = _parentPostalController.text.trim();
        }
        if (_parentCountryController.text.trim().isNotEmpty) {
          studentData['parent_country'] = _parentCountryController.text.trim();
        }

        await _studentService.createStudentFromData(studentData);
      }

      if (mounted) {
        final langService =
            Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.studentId != null
                  ? langService.getString('student_form.student_updated')
                  : langService.getString('student_form.student_saved'),
            ),
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
            content: Text(
              langService.getString(
                'student_form.error_saving',
                params: {'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
                padding: ResponsiveUtils.getResponsiveContentPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPersonalInfoSection(langService),
                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveVerticalSpacing(context),
                    ),
                    _buildEducationSection(langService),
                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveVerticalSpacing(context),
                    ),
                    _buildContactSection(langService),
                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveVerticalSpacing(context),
                    ),
                    _buildParentInfoSection(langService),
                    SizedBox(
                      height: ResponsiveUtils.getResponsiveVerticalSpacing(
                              context,) *
                          2,
                    ),
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
              Consumer<LanguageService>(
                builder: (context, langService, child) => Text(
                  langService
                      .getString('student_form.sections.personal_information'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText:
                              '${langService.getString('student_form.fields.first_name')} *',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) => Validators.required(
                          value,
                          langService
                              .getString('student_form.validators.first_name'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _familyNameController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText:
                              '${langService.getString('student_form.fields.last_name')} *',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) => Validators.required(
                          value,
                          langService
                              .getString('student_form.validators.last_name'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _fatherNameController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: langService
                              .getString('student_form.fields.father_name'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _motherNameController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: langService
                              .getString('student_form.fields.mother_name'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText:
                                '${langService.getString('student_form.fields.birth_date')} *',
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _selectedBirthDate != null
                                ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                                : langService.getString(
                                    'student_form.fields.select_date',
                                  ),
                            style: TextStyle(
                              color: _selectedBirthDate != null
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _birthPlaceController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText:
                              '${langService.getString('student_form.fields.birth_place')} *',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) => Validators.required(
                          value,
                          langService
                              .getString('student_form.fields.birth_place'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _idCardController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: langService
                              .getString('student_form.fields.id_card_number'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _issuingAuthorityController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: langService.getString(
                            'student_form.fields.issuing_authority',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
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
              Consumer<LanguageService>(
                builder: (context, langService, child) => Text(
                  langService
                      .getString('student_form.sections.education_information'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<LanguageService>(
                builder: (context, langService, child) => TextFormField(
                  controller: _universityController,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText:
                        langService.getString('student_form.fields.university'),
                    border: const OutlineInputBorder(),
                    hintText: langService
                        .getString('student_form.fields.university_hint'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _departmentController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: langService
                              .getString('student_form.fields.department'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) =>
                          DropdownButtonFormField<String>(
                        initialValue:
                            (_yearsOfStudy?.contains(_selectedYearOfStudy) ??
                                    false)
                                ? _selectedYearOfStudy
                                : null,
                        decoration: InputDecoration(
                          labelText: langService
                              .getString('student_form.fields.year_of_study'),
                          border: const OutlineInputBorder(),
                        ),
                        items: _yearsOfStudy
                                ?.map(
                                  (year) => DropdownMenuItem(
                                    value: year,
                                    child: Text(year),
                                  ),
                                )
                                .toList() ??
                            [],
                        onChanged: (value) =>
                            setState(() => _selectedYearOfStudy = value),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<LanguageService>(
                builder: (context, langService, child) => CheckboxListTile(
                  title: Text(
                    langService
                        .getString('student_form.fields.has_other_degree'),
                  ),
                  value: _hasOtherDegree,
                  onChanged: (value) =>
                      setState(() => _hasOtherDegree = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
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
              Consumer<LanguageService>(
                builder: (context, langService, child) => Text(
                  langService
                      .getString('student_form.sections.contact_information'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<LanguageService>(
                builder: (context, langService, child) => TextFormField(
                  controller: _emailController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText:
                        '${langService.getString('student_form.fields.email')} *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) =>
                      Validators.emailValidated(value, context),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _phoneController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.phone,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText:
                              '${langService.getString('student_form.fields.phone')} *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        validator: (value) =>
                            Validators.phoneValidated(value, context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (widget.studentId ==
                      null) // Only show password field for new students
                    Expanded(
                      child: Consumer<LanguageService>(
                        builder: (context, langService, child) => TextFormField(
                          controller: _passwordController,
                          textInputAction: TextInputAction.next,
                          obscureText: !_isPasswordVisible,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText:
                                '${langService.getString('student_form.fields.password')} *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) =>
                              Validators.passwordValidated(value, context),
                        ),
                      ),
                    ),
                  if (widget.studentId !=
                      null) // Add spacer for edit mode to maintain layout
                    const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<LanguageService>(
                builder: (context, langService, child) => TextFormField(
                  controller: _taxNumberController,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText:
                        langService.getString('student_form.fields.tax_number'),
                    border: const OutlineInputBorder(),
                  ),
                ),
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
              Consumer<LanguageService>(
                builder: (context, langService, child) => Text(
                  langService
                      .getString('student_form.sections.parent_information'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _fatherJobController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: langService
                              .getString('student_form.fields.father_job'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _motherJobController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: langService
                              .getString('student_form.fields.mother_job'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<LanguageService>(
                builder: (context, langService, child) => TextFormField(
                  controller: _parentAddressController,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText:
                        langService.getString('student_form.fields.address'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _parentCityController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText:
                              langService.getString('student_form.fields.city'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _parentRegionController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: langService
                              .getString('student_form.fields.region'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _parentPostalController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: langService
                              .getString('student_form.fields.postal_code'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<LanguageService>(
                      builder: (context, langService, child) => TextFormField(
                        controller: _parentCountryController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: langService
                              .getString('student_form.fields.country'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildActionButtons(LanguageService langService) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
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
