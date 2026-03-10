import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const CrudApp());
}

class CrudApp extends StatelessWidget {
  const CrudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Vault',
      theme: AppTheme.light(),
      home: const HomePage(),
    );
  }
}

class AppTheme {
  static ThemeData light() {
    const primary = Color(0xFF1D2D44);
    const secondary = Color(0xFF748CAB);
    const accent = Color(0xFFF0A500);
    const surface = Color(0xFFF8F7F4);
    const onSurface = Color(0xFF1A1A1A);

    final colorScheme = const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      tertiary: accent,
      onTertiary: Color(0xFF3B2A00),
      surface: surface,
      onSurface: onSurface,
      error: Color(0xFFD1495B),
      onError: Colors.white,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);
    return base.copyWith(
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.dmSerifDisplay(
          fontSize: 34,
          fontWeight: FontWeight.w400,
          height: 1.05,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.dmSerifDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DFDA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DFDA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
    );
  }
}

class Person {
  Person({
    this.id,
    required this.name,
    required this.email,
    required this.age,
    this.imagePath,
  });

  final int? id;
  final String name;
  final String email;
  final int age;
  final String? imagePath;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'imagePath': imagePath,
    };
  }

  factory Person.fromMap(Map<String, Object?> map) {
    return Person(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      age: map['age'] as int,
      imagePath: map['imagePath'] as String?,
    );
  }
}

class PeopleDb {
  PeopleDb._();

  static final PeopleDb instance = PeopleDb._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'people.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE people (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            age INTEGER NOT NULL,
            imagePath TEXT
          )
        ''');
      },
    );
  }

  Future<List<Person>> fetchAll() async {
    final db = await database;
    final maps = await db.query('people', orderBy: 'id DESC');
    return maps.map(Person.fromMap).toList();
  }

  Future<int> insert(Person person) async {
    final db = await database;
    return db.insert('people', person.toMap());
  }

  Future<int> update(Person person) async {
    final db = await database;
    return db.update(
      'people',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('people', where: 'id = ?', whereArgs: [id]);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PeopleDb _db = PeopleDb.instance;
  List<Person> _people = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    final people = await _db.fetchAll();
    if (!mounted) return;
    setState(() {
      _people = people;
      _loading = false;
    });
  }

  Future<void> _openEditor({Person? person}) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PersonEditorSheet(person: person),
    );
    if (updated == true) {
      await _loadPeople();
    }
  }

  Future<void> _deletePerson(Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete record?'),
          content: Text('Remove ${person.name} from the list?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await _db.delete(person.id!);
    if (!mounted) return;
    await _loadPeople();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Record deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student Vault', style: theme.textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              'Roster dashboard',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add student',
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF8F7F4),
                    const Color(0xFFEFF2F6),
                    const Color(0xFFE6ECF5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                  child: _TopBanner(
                    count: _people.length,
                    loading: _loading,
                    onAdd: () => _openEditor(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _StatsRow(
                    count: _people.length,
                    loading: _loading,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Text('Student directory', style: theme.textTheme.titleMedium),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
                sliver: _loading
                    ? const SliverToBoxAdapter(child: _LoadingState())
                    : _people.isEmpty
                        ? SliverToBoxAdapter(child: EmptyState(onAdd: () => _openEditor()))
                        : SliverList.separated(
                            itemBuilder: (context, index) {
                              final person = _people[index];
                              return Dismissible(
                                key: ValueKey(person.id),
                                direction: DismissDirection.endToStart,
                                background: const _DismissBackground(),
                                confirmDismiss: (_) async {
                                  await _deletePerson(person);
                                  return false;
                                },
                                child: PersonTile(
                                  person: person,
                                  onEdit: () => _openEditor(person: person),
                                  onDelete: () => _deletePerson(person),
                                ),
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemCount: _people.length,
                          ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        backgroundColor: theme.colorScheme.tertiary,
        foregroundColor: theme.colorScheme.onTertiary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TopBanner extends StatelessWidget {
  const _TopBanner({
    required this.count,
    required this.loading,
    required this.onAdd,
  });

  final int count;
  final bool loading;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D2D44), Color(0xFF3E5C76)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your local roster',
            style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            loading ? 'Syncing student records...' : 'Total profiles: $count',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add new student'),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.count, required this.loading});

  final int count;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Profiles',
            value: loading ? '--' : '$count',
            icon: Icons.people_alt_rounded,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _StatCard(
            title: 'Storage',
            value: 'Local',
            icon: Icons.lock_outline_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.secondary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.labelLarge?.copyWith(color: Colors.black54)),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.titleLarge),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 16),
          Text('Loading records...'),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.school_rounded, color: theme.colorScheme.secondary, size: 28),
          ),
          const SizedBox(height: 12),
          Text('No students yet', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Add your first student profile and keep it stored locally.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Create profile'),
          ),
        ],
      ),
    );
  }
}

class PersonTile extends StatelessWidget {
  const PersonTile({
    super.key,
    required this.person,
    required this.onEdit,
    required this.onDelete,
  });

  final Person person;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(imagePath: person.imagePath, name: person.name),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(person.email, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.cake_outlined, size: 16, color: Color(0xFF748CAB)),
                    const SizedBox(width: 6),
                    Text('Age ${person.age}', style: theme.textTheme.labelLarge),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imagePath, required this.name});

  final String? imagePath;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.isEmpty
        ? 'A'
        : name.trim().split(' ').map((part) => part.isNotEmpty ? part[0] : '').take(2).join();
    if (imagePath != null && imagePath!.isNotEmpty && File(imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(imagePath!),
          width: 54,
          height: 54,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF748CAB), Color(0xFF1D2D44)],
        ),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFD1495B),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}

class PersonEditorSheet extends StatefulWidget {
  const PersonEditorSheet({super.key, this.person});

  final Person? person;

  @override
  State<PersonEditorSheet> createState() => _PersonEditorSheetState();
}

class _PersonEditorSheetState extends State<PersonEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  File? _imageFile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final person = widget.person;
    if (person != null) {
      _nameController.text = person.name;
      _emailController.text = person.email;
      _ageController.text = person.age.toString();
      if (person.imagePath != null && person.imagePath!.isNotEmpty) {
        _imageFile = File(person.imagePath!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() {
      _imageFile = File(image.path);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
    });
    final person = Person(
      id: widget.person?.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      imagePath: _imageFile?.path,
    );

    final db = PeopleDb.instance;
    if (widget.person == null) {
      await db.insert(person);
    } else {
      await db.update(person);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.person != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFDFCF9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit student' : 'New student',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1D2D44), Color(0xFF748CAB)],
                        ),
                        image: _imageFile != null
                            ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _imageFile == null
                          ? const Icon(Icons.person, size: 48, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.tertiary,
                          ),
                          child: const Icon(Icons.camera_alt, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Age is required';
                        }
                        final age = int.tryParse(value.trim());
                        if (age == null || age < 1) {
                          return 'Enter a valid age';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? 'Update student' : 'Add student'),
                ),
              ),
              if (_saving) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
