import 'package:flutter/material.dart' show immutable;

@immutable
class StudentReceipt {
  const StudentReceipt({
    required this.id,
    required this.studentId,
    required this.fileName,
    required this.originalFileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.fileType,
    required this.mimeType,
    this.uploadedAt,
    this.compressedSizeBytes = 0,
    this.compressionRatio = 0.0,
    this.metadata = const {},
    this.createdAt,
    this.concernsMonth,
    this.concernsYear,
  });

  factory StudentReceipt.fromJson(Map<String, dynamic> json) => StudentReceipt(
        id: json['id'] as String? ?? '',
        studentId: json['student_id'] as String? ?? '',
        fileName: json['file_name'] as String? ?? '',
        originalFileName: json['original_file_name'] as String? ?? '',
        filePath: json['file_path'] as String? ?? '',
        fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
        fileType: json['file_type'] as String? ?? '',
        mimeType: json['mime_type'] as String? ?? '',
        uploadedAt: json['uploaded_at'] != null
            ? DateTime.tryParse(json['uploaded_at'] as String)
            : null,
        compressedSizeBytes:
            (json['compressed_size_bytes'] as num?)?.toInt() ?? 0,
        compressionRatio:
            (json['compression_ratio'] as num?)?.toDouble() ?? 0.0,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        concernsMonth: (json['concerns_month'] as num?)?.toInt(),
        concernsYear: (json['concerns_year'] as num?)?.toInt(),
      );

  final String id;
  final String studentId;
  final String fileName;
  final String originalFileName;
  final String filePath;
  final int fileSizeBytes;
  final String fileType;
  final String mimeType;
  final DateTime? uploadedAt;
  final int compressedSizeBytes;
  final double compressionRatio;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final int? concernsMonth;
  final int? concernsYear;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentReceipt &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          studentId == other.studentId &&
          fileName == other.fileName &&
          concernsMonth == other.concernsMonth &&
          concernsYear == other.concernsYear;

  @override
  int get hashCode =>
      id.hashCode ^
      studentId.hashCode ^
      fileName.hashCode ^
      concernsMonth.hashCode ^
      concernsYear.hashCode;

  @override
  String toString() =>
      'StudentReceipt(id: $id, studentId: $studentId, fileName: $fileName, concernsMonth: $concernsMonth, concernsYear: $concernsYear)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'file_name': fileName,
        'original_file_name': originalFileName,
        'file_path': filePath,
        'file_size_bytes': fileSizeBytes,
        'file_type': fileType,
        'mime_type': mimeType,
        'uploaded_at': uploadedAt?.toIso8601String(),
        'compressed_size_bytes': compressedSizeBytes,
        'compression_ratio': compressionRatio,
        'metadata': metadata,
        'created_at': createdAt?.toIso8601String(),
        'concerns_month': concernsMonth,
        'concerns_year': concernsYear,
      };

  StudentReceipt copyWith({
    String? id,
    String? studentId,
    String? fileName,
    String? originalFileName,
    String? filePath,
    int? fileSizeBytes,
    String? fileType,
    String? mimeType,
    DateTime? uploadedAt,
    int? compressedSizeBytes,
    double? compressionRatio,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    int? concernsMonth,
    int? concernsYear,
  }) =>
      StudentReceipt(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        fileName: fileName ?? this.fileName,
        originalFileName: originalFileName ?? this.originalFileName,
        filePath: filePath ?? this.filePath,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        fileType: fileType ?? this.fileType,
        mimeType: mimeType ?? this.mimeType,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        compressedSizeBytes: compressedSizeBytes ?? this.compressedSizeBytes,
        compressionRatio: compressionRatio ?? this.compressionRatio,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        concernsMonth: concernsMonth ?? this.concernsMonth,
        concernsYear: concernsYear ?? this.concernsYear,
      );

  String get monthName {
    if (concernsMonth == null) return '';

    const months = [
      '', // 0 index placeholder
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return concernsMonth! >= 1 && concernsMonth! <= 12
        ? months[concernsMonth!]
        : '';
  }

  String get monthNameShort {
    if (concernsMonth == null) return '';

    const months = [
      '', // 0 index placeholder
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return concernsMonth! >= 1 && concernsMonth! <= 12
        ? months[concernsMonth!]
        : '';
  }

  String get periodDescription {
    if (concernsMonth == null && concernsYear == null) return '';
    if (concernsMonth == null) return concernsYear.toString();
    if (concernsYear == null) return monthName;
    return '$monthName $concernsYear';
  }

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  bool get hasValidPeriod => concernsMonth != null && concernsYear != null;
}
