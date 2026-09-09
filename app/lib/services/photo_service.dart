import 'package:image_picker/image_picker.dart';
import 'package:salah/services/photo_storage.dart';

/// Picks an image from the gallery and persists it, returning the stored path
/// (or null if the user cancelled).
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (file == null) return null;
    return persistPickedPhoto(file);
  }
}
