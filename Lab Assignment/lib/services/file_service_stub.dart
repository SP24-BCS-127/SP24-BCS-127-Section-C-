import 'package:file_picker/file_picker.dart';

class FileService {
  static Future<String> copyPickedFile(PlatformFile file) async {
    throw UnsupportedError('File copying is not supported on this platform.');
  }

  static Future<List<String>> copyPickedFiles(List<PlatformFile> files) async {
    throw UnsupportedError('File copying is not supported on this platform.');
  }
}
