import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/patient.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static bool _factoryConfigured = false;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    if (kIsWeb && !_factoryConfigured) {
      databaseFactory = databaseFactoryFfiWeb;
      _factoryConfigured = true;
    }
    final path = kIsWeb
        ? 'doctor_app.db'
        : p.join(
            (await getApplicationDocumentsDirectory()).path,
            'doctor_app.db',
          );
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE patients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age INTEGER NOT NULL,
            gender TEXT NOT NULL,
            phone TEXT NOT NULL,
            diagnosis TEXT NOT NULL,
            notes TEXT NOT NULL,
            lastVisitIso TEXT NOT NULL,
            avatarPath TEXT,
            avatarBytes TEXT,
            documentsJson TEXT NOT NULL,
            documentPaths TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _addColumn(db, 'patients', 'avatarBytes TEXT');
          await _addColumn(db, 'patients', "documentsJson TEXT DEFAULT '[]'");
        }
      },
    );
    return _db!;
  }

  Future<List<Patient>> fetchPatients() async {
    final db = await database;
    final rows = await db.query(
      'patients',
      orderBy: 'lastVisitIso DESC, name COLLATE NOCASE',
    );
    return rows.map(Patient.fromMap).toList();
  }

  Future<int> insertPatient(Patient patient) async {
    final db = await database;
    return db.insert('patients', patient.toMap());
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

  Future<void> _addColumn(Database db, String table, String definition) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $definition');
    } catch (_) {}
  }
}
