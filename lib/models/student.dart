import 'package:flutter/foundation.dart';

@immutable
class Student {
  Student({
    required this.id,
    required this.name,
    required this.familyName,
    required this.fatherName,
    required this.motherName,
    required this.birthDate,
    required this.birthPlace,
    required this.idCardNumber,
    required this.issuingAuthority,
    required this.university,
    required this.department,
    required this.yearOfStudy,
    required this.hasOtherDegree,
    required this.email,
    required this.phone,
    required this.taxNumber,
    required this.fatherJob,
    required this.motherJob,
    required this.parentAddress,
    required this.parentCity,
    required this.parentRegion,
    required this.parentPostal,
    required this.parentCountry,
    required this.parentNumber,
    required this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as String,
        name: json['name'] as String,
        familyName: json['family_name'] as String,
        fatherName: json['father_name'] as String,
        motherName: json['mother_name'] as String,
        birthDate: DateTime.parse(json['birth_date'] as String),
        birthPlace: json['birth_place'] as String,
        idCardNumber: json['id_card_number'] as String,
        issuingAuthority: json['issuing_authority'] as String,
        university: json['university'] as String,
        department: json['department'] as String,
        yearOfStudy: json['year_of_study'] as String,
        hasOtherDegree: json['has_other_degree'] as bool,
        email: json['email'] as String,
        phone: json['phone'] as String,
        taxNumber: json['tax_number'] as String,
        fatherJob: json['father_job'] as String,
        motherJob: json['mother_job'] as String,
        parentAddress: json['parent_address'] as String,
        parentCity: json['parent_city'] as String,
        parentRegion: json['parent_region'] as String,
        parentPostal: json['parent_postal'] as String,
        parentCountry: json['parent_country'] as String,
        parentNumber: json['parent_number'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
  final String id;
  final String name;
  final String familyName;
  final String fatherName;
  final String motherName;
  final DateTime birthDate;
  final String birthPlace;
  final String idCardNumber;
  final String issuingAuthority;
  final String university;
  final String department;
  final String yearOfStudy;
  final bool hasOtherDegree;
  final String email;
  final String phone;
  final String taxNumber;
  final String fatherJob;
  final String motherJob;
  final String parentAddress;
  final String parentCity;
  final String parentRegion;
  final String parentPostal;
  final String parentCountry;
  final String parentNumber;
  final DateTime createdAt;

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
        'university': university,
        'department': department,
        'year_of_study': yearOfStudy,
        'has_other_degree': hasOtherDegree,
        'email': email,
        'phone': phone,
        'tax_number': taxNumber,
        'father_job': fatherJob,
        'mother_job': motherJob,
        'parent_address': parentAddress,
        'parent_city': parentCity,
        'parent_region': parentRegion,
        'parent_postal': parentPostal,
        'parent_country': parentCountry,
        'parent_number': parentNumber,
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toExcelMap() => {
        'ID': id,
        'Name': name,
        'Family Name': familyName,
        'Father Name': fatherName,
        'Mother Name': motherName,
        'Birth Date': birthDate.toIso8601String().split('T')[0],
        'Birth Place': birthPlace,
        'ID Card Number': idCardNumber,
        'Issuing Authority': issuingAuthority,
        'University': university,
        'Department': department,
        'Year of Study': yearOfStudy,
        'Has Other Degree': hasOtherDegree ? 'Yes' : 'No',
        'Email': email,
        'Phone': phone,
        'Tax Number': taxNumber,
        'Father Job': fatherJob,
        'Mother Job': motherJob,
        'Parent Address': parentAddress,
        'Parent City': parentCity,
        'Parent Region': parentRegion,
        'Parent Postal': parentPostal,
        'Parent Country': parentCountry,
        'Parent Number': parentNumber,
        'Created At': createdAt.toIso8601String(),
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
    String? university,
    String? department,
    String? yearOfStudy,
    bool? hasOtherDegree,
    String? email,
    String? phone,
    String? taxNumber,
    String? fatherJob,
    String? motherJob,
    String? parentAddress,
    String? parentCity,
    String? parentRegion,
    String? parentPostal,
    String? parentCountry,
    String? parentNumber,
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
        university: university ?? this.university,
        department: department ?? this.department,
        yearOfStudy: yearOfStudy ?? this.yearOfStudy,
        hasOtherDegree: hasOtherDegree ?? this.hasOtherDegree,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        taxNumber: taxNumber ?? this.taxNumber,
        fatherJob: fatherJob ?? this.fatherJob,
        motherJob: motherJob ?? this.motherJob,
        parentAddress: parentAddress ?? this.parentAddress,
        parentCity: parentCity ?? this.parentCity,
        parentRegion: parentRegion ?? this.parentRegion,
        parentPostal: parentPostal ?? this.parentPostal,
        parentCountry: parentCountry ?? this.parentCountry,
        parentNumber: parentNumber ?? this.parentNumber,
        createdAt: createdAt ?? this.createdAt,
      );

  String get fullName => '$name $familyName';
  String get fullParentAddress =>
      '$parentAddress, $parentCity, $parentRegion $parentPostal, $parentCountry';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Student) return false;
    return other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Student(id: $id, name: $name, familyName: $familyName, email: $email)';
}
