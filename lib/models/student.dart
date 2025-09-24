import 'package:flutter/material.dart' show immutable;

@immutable
class Student {
  const Student({
    required this.id,
    required this.name,
    required this.familyName,
    required this.email,
    required this.birthPlace,
    this.birthDate,
    this.idCardNumber,
    this.fatherName,
    this.motherName,
    this.issuingAuthority,
    this.phone,
    this.taxNumber,
    this.university,
    this.department,
    this.yearOfStudy,
    this.hasOtherDegree = false,
    this.fatherJob,
    this.motherJob,
    this.parentAddress,
    this.parentCity,
    this.parentRegion,
    this.parentPostal,
    this.parentCountry,
    this.parentPhone,
    this.consentDate,
    this.termsAccepted = false,
    this.privacyPolicyAccepted = false,
    this.dataProcessingConsent = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        familyName: json['family_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        fatherName: json['father_name'] as String?,
        motherName: json['mother_name'] as String?,
        birthDate: json['birth_date'] != null
            ? DateTime.tryParse(json['birth_date'].toString())
            : null,
        birthPlace: json['birth_place']?.toString() ?? '',
        idCardNumber: json['id_card_number'] as String?,
        issuingAuthority: json['issuing_authority'] as String?,
        phone: json['phone'] as String?,
        taxNumber: json['tax_number'] as String?,
        university: json['university'] as String?,
        department: json['department'] as String?,
        yearOfStudy: json['year_of_study']?.toString(),
        hasOtherDegree: json['has_other_degree'] as bool? ?? false,
        fatherJob: json['father_job'] as String?,
        motherJob: json['mother_job'] as String?,
        parentAddress: json['parent_address'] as String?,
        parentCity: json['parent_city'] as String?,
        parentRegion: json['parent_region'] as String?,
        parentPostal: json['parent_postal'] as String?,
        parentCountry: json['parent_country'] as String?,
        parentPhone: json['parent_phone'] as String?,
        consentDate: json['consent_date'] != null
            ? DateTime.tryParse(json['consent_date'] as String)
            : null,
        termsAccepted: json['terms_accepted'] as bool? ?? false,
        privacyPolicyAccepted:
            json['privacy_policy_accepted'] as bool? ?? false,
        dataProcessingConsent:
            json['data_processing_consent'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );

  final String id;
  final String name;
  final String familyName;
  final String? fatherName;
  final String? motherName;
  final DateTime? birthDate;
  final String birthPlace;
  final String? idCardNumber;
  final String? issuingAuthority;
  final String? phone;
  final String? taxNumber;
  final String? university;
  final String? department;
  final String? yearOfStudy;
  final bool hasOtherDegree;
  final String email;
  final String? fatherJob;
  final String? motherJob;
  final String? parentAddress;
  final String? parentCity;
  final String? parentRegion;
  final String? parentPostal;
  final String? parentCountry;
  final String? parentPhone;
  final DateTime? consentDate;
  final bool termsAccepted;
  final bool privacyPolicyAccepted;
  final bool dataProcessingConsent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          familyName == other.familyName &&
          email == other.email;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ familyName.hashCode ^ email.hashCode;

  @override
  String toString() =>
      'Student(id: $id, name: $name, familyName: $familyName, email: $email)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'family_name': familyName,
        'father_name': fatherName,
        'mother_name': motherName,
        'birth_date': birthDate?.toIso8601String().split('T')[0],
        'birth_place': birthPlace,
        'id_card_number': idCardNumber,
        'issuing_authority': issuingAuthority,
        'phone': phone,
        'tax_number': taxNumber,
        'university': university,
        'department': department,
        'year_of_study': yearOfStudy,
        'has_other_degree': hasOtherDegree,
        'email': email,
        'father_job': fatherJob,
        'mother_job': motherJob,
        'parent_address': parentAddress,
        'parent_city': parentCity,
        'parent_region': parentRegion,
        'parent_postal': parentPostal,
        'parent_country': parentCountry,
        'parent_phone': parentPhone,
        'consent_date': consentDate?.toIso8601String(),
        'terms_accepted': termsAccepted,
        'privacy_policy_accepted': privacyPolicyAccepted,
        'data_processing_consent': dataProcessingConsent,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  Map<String, dynamic> toExcelMap({String? yesText, String? noText}) => {
        'ID': id,
        'Name': name,
        'Family Name': familyName,
        'Father Name': fatherName ?? '',
        'Mother Name': motherName ?? '',
        'Birth Date': birthDate?.toIso8601String().split('T')[0] ?? '',
        'Birth Place': birthPlace,
        'ID Card Number': idCardNumber ?? '',
        'Issuing Authority': issuingAuthority ?? '',
        'University': university ?? '',
        'Department': department ?? '',
        'Year of Study': yearOfStudy ?? '',
        'Has Other Degree':
            hasOtherDegree ? (yesText ?? 'Yes') : (noText ?? 'No'),
        'Email': email,
        'Phone': phone ?? '',
        'Tax Number': taxNumber ?? '',
        'Father Job': fatherJob ?? '',
        'Mother Job': motherJob ?? '',
        'Parent Address': parentAddress ?? '',
        'Parent City': parentCity ?? '',
        'Parent Region': parentRegion ?? '',
        'Parent Postal': parentPostal ?? '',
        'Parent Country': parentCountry ?? '',
        'Parent Phone': parentPhone ?? '',
        'Terms Accepted': termsAccepted ? (yesText ?? 'Yes') : (noText ?? 'No'),
        'Privacy Policy Accepted':
            privacyPolicyAccepted ? (yesText ?? 'Yes') : (noText ?? 'No'),
        'Data Processing Consent':
            dataProcessingConsent ? (yesText ?? 'Yes') : (noText ?? 'No'),
        'Created At': createdAt?.toIso8601String().split('T')[0] ?? '',
        'Updated At': updatedAt?.toIso8601String().split('T')[0] ?? '',
      };

  Student copyWith({
    String? id,
    String? name,
    String? familyName,
    String? fatherName,
    String? motherName,
    DateTime? birthDate,
    String? birthPlace,
    String? idCardNumber,
    String? issuingAuthority,
    String? phone,
    String? taxNumber,
    String? university,
    String? department,
    String? yearOfStudy,
    bool? hasOtherDegree,
    String? email,
    String? fatherJob,
    String? motherJob,
    String? parentAddress,
    String? parentCity,
    String? parentRegion,
    String? parentPostal,
    String? parentCountry,
    String? parentPhone,
    DateTime? consentDate,
    bool? termsAccepted,
    bool? privacyPolicyAccepted,
    bool? dataProcessingConsent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Student(
        id: id ?? this.id,
        name: name ?? this.name,
        familyName: familyName ?? this.familyName,
        email: email ?? this.email,
        birthDate: birthDate ?? this.birthDate,
        fatherName: fatherName ?? this.fatherName,
        motherName: motherName ?? this.motherName,
        birthPlace: birthPlace ?? this.birthPlace,
        idCardNumber: idCardNumber ?? this.idCardNumber,
        issuingAuthority: issuingAuthority ?? this.issuingAuthority,
        phone: phone ?? this.phone,
        taxNumber: taxNumber ?? this.taxNumber,
        university: university ?? this.university,
        department: department ?? this.department,
        yearOfStudy: yearOfStudy ?? this.yearOfStudy,
        hasOtherDegree: hasOtherDegree ?? this.hasOtherDegree,
        fatherJob: fatherJob ?? this.fatherJob,
        motherJob: motherJob ?? this.motherJob,
        parentAddress: parentAddress ?? this.parentAddress,
        parentCity: parentCity ?? this.parentCity,
        parentRegion: parentRegion ?? this.parentRegion,
        parentPostal: parentPostal ?? this.parentPostal,
        parentCountry: parentCountry ?? this.parentCountry,
        parentPhone: parentPhone ?? this.parentPhone,
        consentDate: consentDate ?? this.consentDate,
        termsAccepted: termsAccepted ?? this.termsAccepted,
        privacyPolicyAccepted:
            privacyPolicyAccepted ?? this.privacyPolicyAccepted,
        dataProcessingConsent:
            dataProcessingConsent ?? this.dataProcessingConsent,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  String get fullName => '$name $familyName'.trim();

  String get fullParentAddress {
    final parts = <String>[];
    if (parentAddress != null && parentAddress!.isNotEmpty) {
      parts.add(parentAddress!);
    }
    if (parentCity != null && parentCity!.isNotEmpty) {
      parts.add(parentCity!);
    }
    if (parentRegion != null && parentRegion!.isNotEmpty) {
      parts.add(parentRegion!);
    }
    if (parentPostal != null && parentPostal!.isNotEmpty) {
      parts.add(parentPostal!);
    }
    if (parentCountry != null && parentCountry!.isNotEmpty) {
      parts.add(parentCountry!);
    }
    return parts.join(', ');
  }

  bool get isComplete =>
      name.isNotEmpty &&
      familyName.isNotEmpty &&
      birthDate != null &&
      birthPlace.isNotEmpty &&
      email.isNotEmpty &&
      (phone?.isNotEmpty ?? false);

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }
}
