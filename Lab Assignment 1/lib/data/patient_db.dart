import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/patient.dart';

class PatientDb {
  PatientDb._internal();
  static final PatientDb instance = PatientDb._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'doctor_desk.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE patients(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age INTEGER NOT NULL,
            gender TEXT NOT NULL,
            phone TEXT NOT NULL,
            condition TEXT NOT NULL,
            notes TEXT NOT NULL,
            last_visit INTEGER,
            attachments TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertPatient(Patient patient) async {
    final db = await database;
    return db.insert('patients', patient.toMap());
  }

  Future<List<Patient>> getPatients() async {
    final db = await database;
    final data = await db.query('patients', orderBy: 'name ASC');
    return data.map(Patient.fromMap).toList();
  }

  Future<Patient?> getPatient(int id) async {
    final db = await database;
    final data = await db.query(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (data.isEmpty) {
      return null;
    }
    return Patient.fromMap(data.first);
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await database;
    return db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<int> deletePatient(int id) async {
    final db = await database;
    return db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }
}
