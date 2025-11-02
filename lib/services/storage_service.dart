import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final ImagePicker _picker = ImagePicker();

  // دالة لاختيار صورة من المعرض
  Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      // طباعة الخطأ لمساعدة المطور
      print('خطأ في اختيار الصورة: $e');
      return null;
    }
  }

  // دالة مساعدة: تختار صورة من المعرض ثم ترفعها إلى Firebase Realtime Database
  // تُرجع مفتاح التسجيل في قاعدة البيانات عند النجاح أو ترمي استثناء برسالة واضحة عند الفشل
  Future<String> pickAndUploadToDatabase({required String folderName}) async {
    final File? file = await pickImage();
    if (file == null) {
      throw Exception('لم يتم اختيار صورة');
    }
    return uploadImageToDatabase(file, folderName);
  }

  // دالة لرفع الملف إلى Firebase Realtime Database كـ Base64 مع معالجة أخطاء مفصلة
  // ملاحظة: هذه الطريقة مناسبة للصور الصغيرة. للصور الكبيرة يفضل استخدام خدمة تخزين مخصصة (Cloud Storage أو CDN).
  Future<String> uploadImageToDatabase(File imageFile, String folderName) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final String base64Data = base64Encode(bytes);

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String path = imageFile.path;
      final String ext = path.contains('.') ? path.split('.').last.toLowerCase() : 'jpg';

      String contentType = 'image/jpeg';
      if (ext == 'png') contentType = 'image/png';
      if (ext == 'gif') contentType = 'image/gif';
      if (ext == 'webp') contentType = 'image/webp';

      final String fileName = '$timestamp.$ext';

      // إنشاء كائن للرفع
      final Map<String, dynamic> payload = {
        'fileName': fileName,
        'contentType': contentType,
        'size': bytes.length,
        'data': base64Data,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final DatabaseReference nodeRef = _db.child(folderName).push();
      await nodeRef.set(payload);

      // Prepare a data URL so existing UI can display it as a single string.
      final String dataUrl = 'data:$contentType;base64,$base64Data';
      return dataUrl;
    } catch (e) {
      final message = 'خطأ في رفع الصورة إلى قاعدة البيانات: $e';
      print(message);
      throw Exception(message);
    }
  }
}