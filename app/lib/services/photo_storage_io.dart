import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Copies a picked image into the app's documents/photos directory and returns
/// the stored path (so it survives beyond the picker's temp file).
Future<String> persistPickedPhoto(XFile file) async {
  final dir = await getApplicationDocumentsDirectory();
  final photosDir = Directory('${dir.path}/photos');
  if (!await photosDir.exists()) {
    await photosDir.create(recursive: true);
  }
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final dest = '${photosDir.path}/photo_${stamp}_${file.name}';
  await File(file.path).copy(dest);
  return dest;
}

ImageProvider photoImageProvider(String path) => FileImage(File(path));
