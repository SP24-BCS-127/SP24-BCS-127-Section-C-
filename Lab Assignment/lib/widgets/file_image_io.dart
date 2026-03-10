import 'dart:io';

import 'package:flutter/widgets.dart';

Widget buildFileImage(String path, {BoxFit fit = BoxFit.cover}) {
  return Image.file(File(path), fit: fit);
}

bool checkFileExists(String path) {
  return File(path).existsSync();
}
