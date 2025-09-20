import 'package:flutter/material.dart' show immutable;

@immutable
class Student {
  const Student({
    required this.id,
    required this.name,
    required this.familyName,
    required this.birthDate,
    required this.idCardNumber,
    required this.email,
    required this.createdAt,
    this.fatherName,
    this.motherName,
    this.birthPlace,
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
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as String,
        name: json['name'] as String,
        familyName: json['family_name'] as String,
        fatherName: json['father_name'] as String?,
        motherName: json['mother_name'] as String?,
        birthDate: DateTime.parse(json['birth_date'] as String),
        birthPlace: json['birth_place'] as String?,
        idCardNumber: json['id_card_number'] as String,
        issuingAuthority: json['issuing_authority'] as String?,
        phone: json['phone'] as String?,
        taxNumber: json['tax_number'] as String?,
        university: json['university'] as String?,
        department: json['department'] as String?,
        yearOfStudy: json['year_of_study']?.toString(),
        hasOtherDegree: json['has_other_degree'] as bool? ?? false,
        email: json['email'] as String? ?? '',
        fatherJob: json['father_job'] as String?,
        motherJob: json['mother_job'] as String?,
        parentAddress: json['parent_address'] as String?,
        parentCity: json['parent_city'] as String?,
        parentRegion: json['parent_region'] as String?,
        parentPostal: json['parent_postal'] as String?,
        parentCountry: json['parent_country'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  final String id;
  final String name;
  final String familyName;
  final String? fatherName;
  final String? motherName;
  final DateTime birthDate;
  final String? birthPlace;
  final String idCardNumber;
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

  final DateTime createdAt;

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
        'birth_date': birthDate.toIso8601String().split('T')[0],
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
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toExcelMap({String? yesText, String? noText}) => {
        'ID': id,
        'Name': name,
        'Family Name': familyName,
        'Father Name': fatherName ?? '',
        'Mother Name': motherName ?? '',
        'Birth Date': birthDate.toIso8601String().split('T')[0],
        'Birth Place': birthPlace ?? '',
        'ID Card Number': idCardNumber,
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
        'Created At': createdAt.toIso8601String().split('T')[0],
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
    DateTime? createdAt,
  }) =>
      Student(
        id: id ?? this.id,
        name: name ?? this.name,
        familyName: familyName ?? this.familyName,
        fatherName: fatherName ?? this.fatherName,
        motherName: motherName ?? this.motherName,
        birthDate: birthDate ?? this.birthDate,
        birthPlace: birthPlace ?? this.birthPlace,
        idCardNumber: idCardNumber ?? this.idCardNumber,
        issuingAuthority: issuingAuthority ?? this.issuingAuthority,
        phone: phone ?? this.phone,
        taxNumber: taxNumber ?? this.taxNumber,
        university: university ?? this.university,
        department: department ?? this.department,
        yearOfStudy: yearOfStudy ?? this.yearOfStudy,
        hasOtherDegree: hasOtherDegree ?? this.hasOtherDegree,
        email: email ?? this.email,
        fatherJob: fatherJob ?? this.fatherJob,
        motherJob: motherJob ?? this.motherJob,
        parentAddress: parentAddress ?? this.parentAddress,
        parentCity: parentCity ?? this.parentCity,
        parentRegion: parentRegion ?? this.parentRegion,
        parentPostal: parentPostal ?? this.parentPostal,
        parentCountry: parentCountry ?? this.parentCountry,
        createdAt: createdAt ?? this.createdAt,
      );

  String get fullName => '$name $familyName'.trim();

  String get fullParentAddress {
    final parts = <String>[];
    if ((parentAddress?.isNotEmpty) ?? false) parts.add(parentAddress!);
    if ((parentCity?.isNotEmpty) ?? false) parts.add(parentCity!);
    if ((parentRegion?.isNotEmpty) ?? false) parts.add(parentRegion!);
    if ((parentPostal?.isNotEmpty) ?? false) parts.add(parentPostal!);
    if ((parentCountry?.isNotEmpty) ?? false) parts.add(parentCountry!);
    return parts.join(', ');
  }

  bool get isComplete =>
      name.isNotEmpty &&
      familyName.isNotEmpty &&
      email.isNotEmpty &&
      idCardNumber.isNotEmpty;

  int? get age {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
