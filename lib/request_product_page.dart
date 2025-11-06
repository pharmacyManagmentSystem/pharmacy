import 'dart:io';
import 'services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/database_service.dart';

class RequestProductPage extends StatefulWidget {
  const RequestProductPage({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.customerEmail,
  });

  final String pharmacyId;
  final String pharmacyName;
  final String customerEmail;

  @override
  State<RequestProductPage> createState() => _RequestProductPageState();
}

class _RequestProductPageState extends State<RequestProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedImage;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.customerEmail;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _productController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _pickedImage = file);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      String? imageUrl;

      if (_pickedImage != null) {
        final file = File(_pickedImage!.path);

        final storageService = StorageService();
        imageUrl = await storageService.uploadImageToDatabase(
          file,
          'product_requests_images/${widget.pharmacyId}',
        );
      }

      final requestRef = DatabaseService.instance
          .ref('product_requests/${widget.pharmacyId}')
          .push();

      await requestRef.set({
        'customerName': _nameController.text.trim(),
        'customerEmail': _emailController.text.trim(),
        'productName': _productController.text.trim(),
        'quantity': _quantityController.text.trim(),
        'notes': _notesController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Thank you!'),
          content: const Text('Your request has been sent to the pharmacy.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to previous screen
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to submit request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Request product - ${widget.pharmacyName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Customer name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter your name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Customer email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || !value.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _productController,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter the product name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity needed'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration:
                    const InputDecoration(labelText: 'Additional notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (_pickedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_pickedImage!.path),
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(_pickedImage == null
                    ? 'Attach image (optional)'
                    : 'Change image'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit request '),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
