import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/patient_db.dart';
import '../../models/patient.dart';

class PatientFormScreen extends StatefulWidget {
  const PatientFormScreen({super.key, this.existing});

  final Patient? existing;

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('MMM d, yyyy');

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _genderController;
  late final TextEditingController _phoneController;
  late final TextEditingController _conditionController;
  late final TextEditingController _notesController;

  DateTime? _lastVisit;
  List<String> _attachments = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _ageController = TextEditingController(text: existing?.age.toString() ?? '');
    _genderController = TextEditingController(text: existing?.gender ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _conditionController = TextEditingController(text: existing?.condition ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _lastVisit = existing?.lastVisit;
    _attachments = List<String>.from(existing?.attachments ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    _conditionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastVisit ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _lastVisit = picked);
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) {
      return;
    }
    final paths = result.paths.whereType<String>().toList();
    setState(() => _attachments = {..._attachments, ...paths}.toList());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final patient = Patient(
      id: widget.existing?.id,
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      gender: _genderController.text.trim(),
      phone: _phoneController.text.trim(),
      condition: _conditionController.text.trim(),
      notes: _notesController.text.trim(),
      lastVisit: _lastVisit,
      attachments: _attachments,
    );
    if (widget.existing == null) {
      await PatientDb.instance.insertPatient(patient);
    } else {
      await PatientDb.instance.updatePatient(patient);
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Patient' : 'New Patient'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SectionTitle(title: 'Patient Info', icon: Icons.person_outline),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Enter patient name' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || int.tryParse(value) == null ? 'Enter age' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _genderController,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Enter gender' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: 'Medical Details', icon: Icons.monitor_heart_outlined),
              const SizedBox(height: 12),
              TextFormField(
                controller: _conditionController,
                decoration: const InputDecoration(labelText: 'Primary Condition'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Enter condition' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _lastVisit != null
                              ? _dateFormat.format(_lastVisit!)
                              : 'Select last visit date',
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: 'Attachments', icon: Icons.attach_file_outlined),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickAttachments,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Documents / Images'),
              ),
              const SizedBox(height: 12),
              if (_attachments.isEmpty)
                Text(
                  'No files attached.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _attachments.map((path) {
                    final fileName = path.split(RegExp(r'[\\/]+')).last;
                    return Chip(
                      label: Text(fileName),
                      onDeleted: () => setState(() => _attachments.remove(path)),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update Patient' : 'Save Patient'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
