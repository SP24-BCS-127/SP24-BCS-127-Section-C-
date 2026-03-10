import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../data/app_database.dart';
import '../models/patient.dart';
import '../services/file_service.dart';
import '../widgets/file_image.dart';

class PatientEditorScreen extends StatefulWidget {
  const PatientEditorScreen({super.key, this.patient});

  final Patient? patient;

  @override
  State<PatientEditorScreen> createState() => _PatientEditorScreenState();
}

class _PatientEditorScreenState extends State<PatientEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('MMM d, yyyy');

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _phoneController;
  late final TextEditingController _diagnosisController;
  late final TextEditingController _notesController;

  String _gender = 'Male';
  DateTime _lastVisit = DateTime.now();
  String? _avatarPath;
  String? _avatarBytesBase64;
  List<PatientDocument> _documents = <PatientDocument>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final patient = widget.patient;
    _nameController = TextEditingController(text: patient?.name ?? '');
    _ageController =
        TextEditingController(text: patient?.age.toString() ?? '');
    _phoneController = TextEditingController(text: patient?.phone ?? '');
    _diagnosisController =
        TextEditingController(text: patient?.diagnosis ?? '');
    _notesController = TextEditingController(text: patient?.notes ?? '');
    _gender = patient?.gender ?? 'Male';
    _lastVisit = patient?.lastVisitIso.isNotEmpty == true
        ? DateTime.parse(patient!.lastVisitIso)
        : DateTime.now();
    _avatarPath = patient?.avatarPath;
    _avatarBytesBase64 = patient?.avatarBytesBase64;
    _documents = List.of(patient?.documents ?? <PatientDocument>[]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) return;
      setState(() {
        _avatarBytesBase64 = base64Encode(bytes);
        _avatarPath = null;
      });
    } else {
      final copied = await FileService.copyPickedFile(file);
      setState(() {
        _avatarPath = copied;
        _avatarBytesBase64 = null;
      });
    }
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    if (kIsWeb) {
      final added = result.files
          .where((file) => file.bytes != null)
          .map(
            (file) => PatientDocument(
              name: file.name,
              bytesBase64: base64Encode(file.bytes!),
            ),
          )
          .toList();
      setState(() => _documents.addAll(added));
    } else {
      final copied = await FileService.copyPickedFiles(result.files);
      final added = <PatientDocument>[];
      for (var i = 0; i < copied.length; i++) {
        final path = copied[i];
        final name = i < result.files.length
            ? result.files[i].name
            : p.basename(path);
        added.add(PatientDocument(name: name, path: path));
      }
      setState(() => _documents.addAll(added));
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final patient = Patient(
      id: widget.patient?.id,
      name: _nameController.text.trim(),
      age: age,
      gender: _gender,
      phone: _phoneController.text.trim(),
      diagnosis: _diagnosisController.text.trim(),
      notes: _notesController.text.trim(),
      lastVisitIso: _lastVisit.toIso8601String(),
      avatarPath: _avatarPath,
      avatarBytesBase64: _avatarBytesBase64,
      documents: _documents,
    );
    final db = AppDatabase.instance;
    try {
      if (widget.patient == null) {
        await db.insertPatient(patient);
      } else {
        await db.updatePatient(patient);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save patient: $error')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  Future<void> _pickLastVisit() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastVisit,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _lastVisit = picked);
  }

  void _removeDocument(PatientDocument doc) {
    setState(() => _documents.remove(doc));
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF101826);
    const sea = Color(0xFF2EC4B6);
    const coral = Color(0xFFFF9F1C);
    const sky = Color(0xFFE9F4F3);
    const fog = Color(0xFFF5F6F8);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ink,
        title: Text(widget.patient == null ? 'New Patient' : 'Edit Patient'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: fog),
            Positioned(
              top: -120,
              right: -60,
              child: _GlowCircle(color: sea.withOpacity(0.18), size: 220),
            ),
            Positioned(
              bottom: -140,
              left: -80,
              child: _GlowCircle(color: coral.withOpacity(0.12), size: 260),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(
                      title: widget.patient == null
                          ? 'Patient Dossier'
                          : 'Patient Dossier',
                      subtitle: widget.patient == null
                          ? 'Create a complete profile for care.'
                          : 'Update and refine the record.',
                      status: widget.patient == null ? 'New Case' : 'Active',
                      accent: sea,
                      avatarPath: _avatarPath,
                      avatarBytesBase64: _avatarBytesBase64,
                      onAvatarTap: _pickAvatar,
                    ),
                    const SizedBox(height: 16),
                    _MiniStats(
                      accent: sea,
                      secondary: coral,
                      ageText: _ageController.text.trim().isEmpty
                          ? '--'
                          : _ageController.text.trim(),
                      genderText: _gender,
                      lastVisitText: _dateFormat.format(_lastVisit),
                      docCount: _documents.length,
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Identity',
                      icon: Icons.badge_outlined,
                      accent: sea,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: _fieldDecoration(
                              label: 'Full name',
                              icon: Icons.person_outline,
                              accent: sea,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter a patient name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: _fieldDecoration(
                                    label: 'Age',
                                    icon: Icons.cake_outlined,
                                    accent: sea,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Age required';
                                    }
                                    final parsed = int.tryParse(value.trim());
                                    if (parsed == null || parsed <= 0) {
                                      return 'Enter a valid age';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _gender,
                                  decoration: _fieldDecoration(
                                    label: 'Gender',
                                    icon: Icons.wc_outlined,
                                    accent: sea,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Male',
                                      child: Text('Male'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Female',
                                      child: Text('Female'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Other',
                                      child: Text('Other'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _gender = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Contact & Visit',
                      icon: Icons.call_outlined,
                      accent: coral,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _fieldDecoration(
                                label: 'Phone number',
                                icon: Icons.phone_outlined,
                                accent: coral,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Phone required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _pickLastVisit,
                              borderRadius: BorderRadius.circular(16),
                              child: InputDecorator(
                                decoration: _fieldDecoration(
                                  label: 'Last visit',
                                  icon: Icons.event_outlined,
                                  accent: coral,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_dateFormat.format(_lastVisit)),
                                    const Icon(Icons.calendar_today, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Clinical Notes',
                      icon: Icons.monitor_heart_outlined,
                      accent: sea,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _diagnosisController,
                            decoration: _fieldDecoration(
                              label: 'Diagnosis',
                              icon: Icons.medical_information_outlined,
                              accent: sea,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            decoration: _fieldDecoration(
                              label: 'Notes',
                              icon: Icons.sticky_note_2_outlined,
                              accent: sea,
                              alignLabelWithHint: true,
                            ),
                            minLines: 4,
                            maxLines: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Documents Vault',
                      icon: Icons.inventory_2_outlined,
                      accent: coral,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.icon(
                                onPressed: _pickDocuments,
                                style: FilledButton.styleFrom(
                                  backgroundColor: coral,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Add Documents'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _documents.isEmpty
                                    ? null
                                    : () => setState(() => _documents.clear()),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Clear All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_documents.isEmpty)
                            const Text('No documents uploaded yet.')
                          else
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _documents
                                  .map(
                                    (doc) => _DocChip(
                                      document: doc,
                                      accent: coral,
                                      onRemove: () => _removeDocument(doc),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ActionCard(
                      accent: sea,
                      onPressed: _saving ? null : _savePatient,
                      saving: _saving,
                      label: widget.patient == null
                          ? 'Create Patient'
                          : 'Save Changes',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    required Color accent,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: accent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accent.withOpacity(0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accent.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accent, width: 1.6),
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.accent,
    required this.avatarPath,
    required this.avatarBytesBase64,
    required this.onAvatarTap,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color accent;
  final String? avatarPath;
  final String? avatarBytesBase64;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          _AvatarBadge(
            path: avatarPath,
            bytesBase64: avatarBytesBase64,
            onTap: onAvatarTap,
            accent: accent,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.path,
    required this.bytesBase64,
    required this.onTap,
    required this.accent,
  });

  final String? path;
  final String? bytesBase64;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        height: 88,
        width: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: accent.withOpacity(0.12),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        child: _buildAvatar(),
      ),
    );
  }

  Widget _buildAvatar() {
    final bytes = _decode(bytesBase64);
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.memory(bytes, fit: BoxFit.cover),
      );
    }
    if (path != null && fileExists(path!)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: fileImage(path!, fit: BoxFit.cover),
      );
    }
    return Icon(Icons.person, size: 42, color: accent);
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

class _MiniStats extends StatelessWidget {
  const _MiniStats({
    required this.accent,
    required this.secondary,
    required this.ageText,
    required this.genderText,
    required this.lastVisitText,
    required this.docCount,
  });

  final Color accent;
  final Color secondary;
  final String ageText;
  final String genderText;
  final String lastVisitText;
  final int docCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatPill(
            label: 'Age',
            value: ageText,
            color: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatPill(
            label: 'Gender',
            value: genderText,
            color: secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatPill(
            label: 'Last visit',
            value: lastVisitText,
            color: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatPill(
            label: 'Docs',
            value: docCount.toString(),
            color: secondary,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DocChip extends StatelessWidget {
  const _DocChip({
    required this.document,
    required this.accent,
    required this.onRemove,
  });

  final PatientDocument document;
  final Color accent;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final fileName = document.name.isEmpty
        ? (document.path == null ? 'Document' : p.basename(document.path!))
        : document.name;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 16, color: accent),
          const SizedBox(width: 6),
          SizedBox(
            width: 120,
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
            icon: const Icon(Icons.close, size: 16),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.accent,
    required this.onPressed,
    required this.saving,
    required this.label,
  });

  final Color accent;
  final VoidCallback? onPressed;
  final bool saving;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.3),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: accent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          child: saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(label),
        ),
      ),
    );
  }
}
