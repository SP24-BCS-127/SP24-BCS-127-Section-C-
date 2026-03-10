import 'package:flutter/widgets.dart';

import 'file_image_stub.dart'
    if (dart.library.io) 'file_image_io.dart';

Widget fileImage(String path, {BoxFit fit = BoxFit.cover}) {
  return buildFileImage(path, fit: fit);
}

bool fileExists(String path) {
  return checkFileExists(path);
}
