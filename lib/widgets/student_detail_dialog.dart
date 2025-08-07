import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../services/language_service.dart';

class StudentDetailDialog extends StatelessWidget {

  const StudentDetailDialog({required this.student, super.key});
  final Student student;

  @override
  Widget build(BuildContext context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : 'S',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Consumer<LanguageService>(
                        builder: (context, langService, child) => Text(
                            '${langService.getString('student_detail.student_id')}: ${student.id}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ),
                    ],
                  ),
                ),
                Consumer<LanguageService>(
                  builder: (context, langService, child) => IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: langService.getString('student_detail.close'),
                    ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Consumer<LanguageService>(
                  builder: (context, langService, child) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                            langService.getString(
                                'student_detail.personal_information',),
                            Icons.person,
                            [
                              _buildInfoRow(
                                  langService
                                      .getString('student_detail.full_name'),
                                  student.fullName,
                                  langService,),
                              _buildInfoRow(
                                  langService
                                      .getString('student_detail.father_name'),
                                  student.fatherName,
                                  langService,),
                              _buildInfoRow(
                                  langService
                                      .getString('student_detail.mother_name'),
                                  student.motherName,
                                  langService,),
                              _buildInfoRow(
                                langService
                                    .getString('student_detail.birth_date'),
                                DateFormat('dd/MM/yyyy')
                                    .format(student.birthDate),
                                langService,
                              ),
                              _buildInfoRow(
                                  langService
                                      .getString('student_detail.birth_place'),
                                  student.birthPlace,
                                  langService,),
                            ],
                            langService,),
                        _buildSection(
                            langService
                                .getString('student_detail.identification'),
                            Icons.badge,
                            [
                              _buildInfoRow(
                                  langService.getString(
                                      'student_detail.id_card_number',),
                                  student.idCardNumber,
                                  langService,),
                              _buildInfoRow(
                                langService.getString(
                                    'student_detail.issuing_authority',),
                                student.issuingAuthority,
                                langService,
                              ),
                              _buildInfoRow(
                                  langService
                                      .getString('student_detail.tax_number'),
                                  student.taxNumber,
                                  langService,),
                            ],
                            langService,),
                        _buildSection(
                            langService.getString(
                                'student_detail.academic_information',),
                            Icons.school,
                            [
                              _buildInfoRow(
                                  langService
                                      .getString('student_detail.university'),
                                  student.university,
                                  langService,),
                              _buildInfoRow(
                                  langService
                                      .getString('student_detail.department'),
                                  student.department,
                                  langService,),
                              _buildInfoRow(
                                  langService.getString(
                                      'student_detail.year_of_study',),
                                  student.yearOfStudy,
                                  langService,),
                              _buildInfoRow(
                                langService.getString(
                                    'student_detail.has_other_degree',),
                                student.hasOtherDegree
                                    ? langService
                                        .getString('student_detail.yes')
                                    : langService
                                        .getString('student_detail.no'),
                                langService,
                              ),
                            ],
                            langService,),
                        _buildSection(
                            langService.getString(
                                'student_detail.contact_information',),
                            Icons.contact_mail,
                            [
                              _buildInfoRow(
                                  langService.getString('student_detail.email'),
                                  student.email,
                                  langService,
                                  isEmail: true,),
                              _buildInfoRow(
                                  langService.getString('student_detail.phone'),
                                  student.phone,
                                  langService,
                                  isPhone: true,),
                            ],
                            langService,),
                        _buildSection(
                            langService
                                .getString('student_detail.family_information'),
                            Icons.family_restroom,
                            [
                              _buildInfoRow(
                                  langService
                                      .getString('student_detail.father_job'),
                                  student.fatherJob,
                                  langService,),
                              _buildInfoRow(
                                  langService
                                      .getString('student_detail.mother_job'),
                                  student.motherJob,
                                  langService,),
                            ],
                            langService,),
                        _buildSection(
                            langService.getString(
                                'student_detail.address_information',),
                            Icons.location_on,
                            [
                              _buildInfoRow(
                                  langService
                                      .getString('student_detail.address'),
                                  student.parentAddress,
                                  langService,),
                              _buildInfoRow(
                                  langService.getString('student_detail.city'),
                                  student.parentCity,
                                  langService,),
                              _buildInfoRow(
                                  langService
                                      .getString('student_detail.region'),
                                  student.parentRegion,
                                  langService,),
                              _buildInfoRow(
                                  langService
                                      .getString('student_detail.postal_code'),
                                  student.parentPostal,
                                  langService,),
                              _buildInfoRow(
                                  langService
                                      .getString('student_detail.country'),
                                  student.parentCountry,
                                  langService,),
                              _buildInfoRow(
                                langService
                                    .getString('student_detail.parent_contact'),
                                student.parentNumber,
                                langService,
                                isPhone: true,
                              ),
                            ],
                            langService,),
                        _buildSection(
                            langService
                                .getString('student_detail.system_information'),
                            Icons.info,
                            [
                              _buildInfoRow(
                                langService
                                    .getString('student_detail.created_at'),
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(student.createdAt),
                                langService,
                              ),
                            ],
                            langService,),
                      ],
                    ),
                ),
              ),
            ),

            // Footer
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Consumer<LanguageService>(
                  builder: (context, langService, child) => TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child:
                          Text(langService.getString('student_detail.close')),
                    ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildSection(String title, IconData icon, List<Widget> children,
      LanguageService langService,) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );

  Widget _buildInfoRow(
    String label,
    String value,
    LanguageService langService, {
    bool isEmail = false,
    bool isPhone = false,
  }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  value.isNotEmpty ? value : 'Not provided',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color:
                        value.isNotEmpty ? Colors.grey[800] : Colors.grey[500],
                    decoration:
                        isEmail || isPhone ? TextDecoration.underline : null,
                  ),
                ),
              ),
              if (isEmail && value.isNotEmpty)
                IconButton(
                  onPressed: () {
                    // Could implement email functionality here
                  },
                  icon: Icon(Icons.email, size: 16, color: Colors.blue[600]),
                  tooltip: 'Send Email',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              if (isPhone && value.isNotEmpty)
                IconButton(
                  onPressed: () {
                    // Could implement call functionality here
                  },
                  icon: Icon(Icons.phone, size: 16, color: Colors.green[600]),
                  tooltip: 'Call',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
}
