import 'dart:convert';

import 'package:path/path.dart' as p;

class PatientDocument {
  const PatientDocument({
    required this.name,
    this.path,
    this.bytesBase64,
  });

  final String name;
  final String? path;
  final String? bytesBase64;

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'path': path,
      'bytesBase64': bytesBase64,
    };
  }

  static PatientDocument fromJson(Map<String, Object?> map) {
    return PatientDocument(
      name: (map['name'] as String?) ?? 'Document',
      path: map['path'] as String?,
      bytesBase64: map['bytesBase64'] as String?,
    );
  }
}

class Patient {
  const Patient({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.diagnosis,
    required this.notes,
    required this.lastVisitIso,
    required this.avatarPath,
    required this.avatarBytesBase64,
    required this.documents,
  });

  final int? id;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String diagnosis;
  final String notes;
  final String lastVisitIso;
  final String? avatarPath;
  final String? avatarBytesBase64;
  final List<PatientDocument> documents;

  Patient copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    String? phone,
    String? diagnosis,
    String? notes,
    String? lastVisitIso,
    String? avatarPath,
    String? avatarBytesBase64,
    List<PatientDocument>? documents,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      diagnosis: diagnosis ?? this.diagnosis,
      notes: notes ?? this.notes,
      lastVisitIso: lastVisitIso ?? this.lastVisitIso,
      avatarPath: avatarPath ?? this.avatarPath,
      avatarBytesBase64: avatarBytesBase64 ?? this.avatarBytesBase64,
      documents: documents ?? this.documents,
    );
  }

  Map<String, Object?> toMap() {
    final documentPaths = documents
        .where((doc) => doc.path != null)
        .map((doc) => doc.path)
        .whereType<String>()
        .toList();
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'diagnosis': diagnosis,
      'notes': notes,
      'lastVisitIso': lastVisitIso,
      'avatarPath': avatarPath,
      'avatarBytes': avatarBytesBase64,
      'documentsJson': jsonEncode(documents.map((e) => e.toJson()).toList()),
      'documentPaths': jsonEncode(documentPaths),
    };
  }

  static Patient fromMap(Map<String, Object?> map) {
    final documentsJson = map['documentsJson'] as String?;
    final documents = _decodeDocuments(documentsJson);
    final legacyPaths = _decodePaths(map['documentPaths']);
    if (documents.isEmpty && legacyPaths.isNotEmpty) {
      documents.addAll(
        legacyPaths.map(
          (path) => PatientDocument(
            name: p.basename(path),
            path: path,
          ),
        ),
      );
    }
    return Patient(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      age: (map['age'] as int?) ?? 0,
      gender: (map['gender'] as String?) ?? 'Not set',
      phone: (map['phone'] as String?) ?? '',
      diagnosis: (map['diagnosis'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      lastVisitIso: (map['lastVisitIso'] as String?) ?? '',
      avatarPath: map['avatarPath'] as String?,
      avatarBytesBase64: map['avatarBytes'] as String?,
      documents: documents,
    );
  }

  static List<String> _decodePaths(Object? raw) {
    if (raw == null) {
      return <String>[];
    }
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    }
    return <String>[];
  }

  static List<PatientDocument> _decodeDocuments(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <PatientDocument>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, Object?>.from(e))
          .map(PatientDocument.fromJson)
          .toList();
    }
    return <PatientDocument>[];
  }
}
