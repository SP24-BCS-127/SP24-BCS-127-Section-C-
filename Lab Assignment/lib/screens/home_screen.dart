import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../models/patient.dart';
import 'patient_editor_screen.dart';
import '../widgets/file_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _db = AppDatabase.instance;
  final _dateFormat = DateFormat('MMM d, yyyy');

  List<Patient> _patients = <Patient>[];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);
    try {
      final data = await _db.fetchPatients();
      if (!mounted) return;
      setState(() {
        _patients = data;
        _loading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Unable to load patients. ${error.toString()}';
      });
    }
  }

  Future<void> _openEditor({Patient? patient}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientEditorScreen(patient: patient),
      ),
    );
    await _loadPatients();
  }

  Future<void> _deletePatient(Patient patient) async {
    if (patient.id == null) return;
    await _db.deletePatient(patient.id!);
    await _loadPatients();
  }

  List<Patient> get _filteredPatients {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _patients;
    }
    return _patients.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.phone.toLowerCase().contains(query) ||
          p.diagnosis.toLowerCase().contains(query);
    }).toList();
  }

  int get _totalDocuments {
    var total = 0;
    for (final patient in _patients) {
      total += patient.documents.length;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF101826);
    const teal = Color(0xFF2EC4B6);
    const coral = Color(0xFFFF9F1C);
    const sky = Color(0xFFEFF7F6);
    const fog = Color(0xFFF5F6F8);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: teal,
        icon: const Icon(Icons.add),
        label: const Text('New Patient'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: fog),
            Positioned(
              top: -120,
              right: -60,
              child: _GlowCircle(color: teal.withOpacity(0.16), size: 220),
            ),
            Positioned(
              bottom: -140,
              left: -80,
              child: _GlowCircle(color: coral.withOpacity(0.12), size: 260),
            ),
            Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _TopBanner(
                    title: 'Doctor Desk',
                    subtitle: 'Monitor patients, visits, and documents.',
                    onRefresh: _loadPatients,
                    accent: teal,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SearchBar(
                    controller: _searchController,
                    accent: teal,
                    hint: 'Search by name, phone, or diagnosis',
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SummaryStrip(
                    primary: teal,
                    secondary: coral,
                    totalPatients: _patients.length,
                    showing: _filteredPatients.length,
                    totalDocs: _totalDocuments,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? _ErrorState(
                              message: _errorMessage!,
                              onRetry: _loadPatients,
                            )
                          : _filteredPatients.isEmpty
                              ? _EmptyState(onCreate: () => _openEditor())
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 6, 20, 24),
                                  itemCount: _filteredPatients.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final patient = _filteredPatients[index];
                                    return Dismissible(
                                      key: ValueKey('patient_${patient.id}_$index'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding:
                                            const EdgeInsets.only(right: 24),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade400,
                                          borderRadius:
                                              BorderRadius.circular(22),
                                        ),
                                        child: const Icon(
                                          Icons.delete_forever,
                                          color: Colors.white,
                                        ),
                                      ),
                                      confirmDismiss: (_) async {
                                        return await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete patient?'),
                                            content: Text(
                                              'Remove ${patient.name} from records?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      onDismissed: (_) => _deletePatient(patient),
                                      child: _PatientTile(
                                        patient: patient,
                                        dateFormat: _dateFormat,
                                        onTap: () =>
                                            _openEditor(patient: patient),
                                        accent: teal,
                                        secondary: coral,
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _TopBanner extends StatelessWidget {
  const _TopBanner({
    required this.title,
    required this.subtitle,
    required this.onRefresh,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRefresh;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101826),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            color: accent,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.accent,
    required this.hint,
  });

  final TextEditingController controller;
  final Color accent;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search, color: accent),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: accent.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: accent.withOpacity(0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.primary,
    required this.secondary,
    required this.totalPatients,
    required this.showing,
    required this.totalDocs,
  });

  final Color primary;
  final Color secondary;
  final int totalPatients;
  final int showing;
  final int totalDocs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total patients',
            value: totalPatients.toString(),
            color: primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Showing',
            value: showing.toString(),
            color: secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Documents',
            value: totalDocs.toString(),
            color: primary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({
    required this.patient,
    required this.dateFormat,
    required this.onTap,
    required this.accent,
    required this.secondary,
  });

  final Patient patient;
  final DateFormat dateFormat;
  final VoidCallback onTap;
  final Color accent;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastVisit = patient.lastVisitIso.isEmpty
        ? 'Not set'
        : dateFormat.format(DateTime.parse(patient.lastVisitIso));
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 76,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            _AvatarSquare(
              path: patient.avatarPath,
              bytesBase64: patient.avatarBytesBase64,
              initials: patient.name,
              accent: accent,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          patient.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _Tag(text: patient.gender, color: secondary),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    patient.diagnosis.isEmpty
                        ? 'No diagnosis yet'
                        : patient.diagnosis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MetaPill(
                        icon: Icons.calendar_today,
                        label: lastVisit,
                        color: accent,
                      ),
                      const SizedBox(width: 8),
                      _MetaPill(
                        icon: Icons.folder_open,
                        label: '${patient.documents.length} docs',
                        color: secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}

class _AvatarSquare extends StatelessWidget {
  const _AvatarSquare({
    required this.path,
    required this.bytesBase64,
    required this.initials,
    required this.accent,
  });

  final String? path;
  final String? bytesBase64;
  final String initials;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fallback = initials.trim().isEmpty
        ? 'DR'
        : initials.trim().split(' ').map((e) => e[0]).take(2).join();
    final bytes = _decode(bytesBase64);
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accent.withOpacity(0.12),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: bytes != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(bytes, fit: BoxFit.cover),
            )
          : path != null && fileExists(path!)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: fileImage(path!, fit: BoxFit.cover),
                )
              : Center(
                  child: Text(
                    fallback.toUpperCase(),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
    );
  }

  Uint8List? _decode(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.medical_information, size: 56, color: Colors.teal),
            const SizedBox(height: 12),
            const Text(
              'No patients yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add the first patient to start tracking medical records.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Add Patient'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
