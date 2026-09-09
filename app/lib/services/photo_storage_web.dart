import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

/// On web (preview only) we keep the picker's object URL. It lives for the
/// session; persistence is a mobile concern.
Future<String> persistPickedPhoto(XFile file) async => file.path;

ImageProvider photoImageProvider(String path) => NetworkImage(path);
