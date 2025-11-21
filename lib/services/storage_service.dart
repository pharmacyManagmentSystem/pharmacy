import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      print('خطأ في اختيار الصورة: $e');
      return null;
    }
  }

  Future<String> pickAndUploadToDatabase({required String folderName}) async {
    final File? file = await pickImage();
    if (file == null) {
      throw Exception('لم يتم اختيار صورة');
    }
    return uploadImageToDatabase(file, folderName);
  }

  Future<String> uploadImageToDatabase(
      File imageFile, String folderName) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final String base64Data = base64Encode(bytes);

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String path = imageFile.path;
      final String ext =
          path.contains('.') ? path.split('.').last.toLowerCase() : 'jpg';

      String contentType = 'image/jpeg';
      if (ext == 'png') contentType = 'image/png';
      if (ext == 'gif') contentType = 'image/gif';
      if (ext == 'webp') contentType = 'image/webp';

      final String fileName = '$timestamp.$ext';

      final Map<String, dynamic> payload = {
        'fileName': fileName,
        'contentType': contentType,
        'size': bytes.length,
        'data': base64Data,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final DatabaseReference nodeRef = _db.child(folderName).push();
      await nodeRef.set(payload);

      final String dataUrl = 'data:$contentType;base64,$base64Data';
      return dataUrl;
    } catch (e) {
      final message = 'خطأ في رفع الصورة إلى قاعدة البيانات: $e';
      print(message);
      throw Exception(message);
    }
  }
}
