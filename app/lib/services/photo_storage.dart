// Platform-specific photo persistence. The io variant copies picked files into
// app storage (mobile/desktop); the web variant keeps the picker's blob URL
// (preview only). The conditional import keeps `dart:io` out of the web build.
export 'photo_storage_io.dart'
    if (dart.library.html) 'photo_storage_web.dart';
