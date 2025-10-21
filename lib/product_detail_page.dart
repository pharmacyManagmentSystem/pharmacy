import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'models/product.dart';
import 'state/customer_app_state.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product, required this.pharmacyName});
  final Product product;
  final String pharmacyName;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ImagePicker _picker = ImagePicker();
  String? _prescriptionUrl;
  bool _uploading = false;

  Future<void> _uploadPrescription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance
          .ref('prescriptions/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      setState(() => _prescriptionUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _uploading = false);
    }
  }

  Widget _buildProductImage(String path) {
    // ✅ إذا كان يبدأ بـ "http" => من الإنترنت
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
      );
    }
    // ✅ إذا كان يحتوي "assets/" أو فقط اسم الصورة => من المشروع المحلي
    else if (path.contains('assets/') || path.endsWith('.jpg') || path.endsWith('.png')) {
      final fixedPath = path.startsWith('assets/') ? path : 'assets/$path';
      return Image.asset(
        fixedPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 60),
      );
    }
    // ✅ حالة افتراضية إذا لم يوجد مسار
    else {
      return const Icon(Icons.image_not_supported, size: 60);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildProductImage(p.imageUrl),
            ),
          ),
          const SizedBox(height: 16),
          Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Category: ${p.category}'),
          const SizedBox(height: 8),
          Text('Price: ${p.price.toStringAsFixed(2)} OMR',
              style: const TextStyle(color: Colors.green, fontSize: 18)),
          const SizedBox(height: 12),
          Text(p.description.isNotEmpty ? p.description : 'No description available.'),
          const SizedBox(height: 20),
          if (p.requiresPrescription)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _prescriptionUrl == null
                      ? 'Prescription required.'
                      : 'Prescription uploaded.',
                  style: TextStyle(
                      color: _prescriptionUrl == null ? Colors.red : Colors.green),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _uploading ? null : _uploadPrescription,
                  icon: _uploading
                      ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file),
                  label: Text(_prescriptionUrl == null ? 'Upload prescription' : 'Replace'),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Consumer<CustomerAppState>(
            builder: (context, state, _) => FilledButton(
              onPressed: () {
                if (p.requiresPrescription && _prescriptionUrl == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please upload a prescription first.')),
                  );
                  return;
                }
                state.addProductToCart(p, pharmacyName: widget.pharmacyName, prescriptionUrl: _prescriptionUrl);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${p.name} added to cart')),
                );
              },
              child: const Text('Add to cart'),
            ),
          ),
        ],
      ),
    );
  }
}

