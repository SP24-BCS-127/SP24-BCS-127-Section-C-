import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileService {
  static Future<String> copyPickedFile(PlatformFile file) async {
    final origin = file.path;
    if (origin == null) {
      throw StateError('Selected file has no path.');
    }
    final directory = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(directory.path, 'patient_files'));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = file.name.replaceAll(RegExp(r'\s+'), '_');
    final targetPath = p.join(targetDir.path, '${stamp}_$safeName');
    return File(origin).copy(targetPath).then((f) => f.path);
  }

  static Future<List<String>> copyPickedFiles(List<PlatformFile> files) async {
    final copied = <String>[];
    for (final file in files) {
      copied.add(await copyPickedFile(file));
    }
    return copied;
  }
}
