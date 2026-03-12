import 'dart:convert';

class Patient {
  final int? id;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String condition;
  final String notes;
  final DateTime? lastVisit;
  final List<String> attachments;

  const Patient({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.condition,
    required this.notes,
    required this.lastVisit,
    required this.attachments,
  });

  Patient copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    String? phone,
    String? condition,
    String? notes,
    DateTime? lastVisit,
    List<String>? attachments,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      condition: condition ?? this.condition,
      notes: notes ?? this.notes,
      lastVisit: lastVisit ?? this.lastVisit,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'condition': condition,
      'notes': notes,
      'last_visit': lastVisit?.millisecondsSinceEpoch,
      'attachments': jsonEncode(attachments),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    final attachmentsRaw = map['attachments'] as String? ?? '[]';
    final decoded = jsonDecode(attachmentsRaw);
    return Patient(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      age: (map['age'] as int?) ?? 0,
      gender: (map['gender'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      condition: (map['condition'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      lastVisit: map['last_visit'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_visit'] as int)
          : null,
      attachments: decoded is List
          ? decoded.map((e) => e.toString()).toList()
          : <String>[],
    );
  }
}
