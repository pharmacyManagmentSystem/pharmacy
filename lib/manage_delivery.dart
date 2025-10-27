import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'package:image_picker/image_picker.dart';
import 'services/storage_service.dart';

class ManageDeliveryPage extends StatefulWidget {
  const ManageDeliveryPage({super.key});

  @override
  State<ManageDeliveryPage> createState() => _ManageDeliveryPageState();
}

class _ManageDeliveryPageState extends State<ManageDeliveryPage> {
  final DatabaseReference dbRef =
  DatabaseService.instance.ref("pharmacy/delivery_persons");
  String searchQuery = "";
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(String uid) async {
    final storageService = StorageService();
    final dataUrl = await storageService.uploadImageToDatabase(
      _selectedImage!,
      'pharmacy/delivery_persons',
    );
    return dataUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100], // Baby blue background
      appBar: AppBar(
        title: const Text(
          "Manage Delivery",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor:  Color(0xFF0288D1), // Blue AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // ➕ Add new delivery person button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addDeliveryDialog(context),
                icon: const Icon(Icons.add),
                label: const Text("Add New Delivery Person"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 16), // Space between button and search bar

            // 🔍 Search bar
            TextField(
              decoration: const InputDecoration(
                labelText: "Search by Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 16), // Space between search bar and list

            // 📋 Delivery cards
            Expanded(
              child: StreamBuilder(
                stream: dbRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading data"));
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(
                        child: Text("No delivery persons found"));
                  }

                  final event = snapshot.data! as DatabaseEvent;
                  final raw = event.snapshot.value;

                  if (raw is! Map<dynamic, dynamic>) {
                    return const Center(
                        child: Text("No delivery persons found"));
                  }

                  final deliveryList = raw.entries
                      .where((entry) => entry.value is Map)
                      .map(
                        (entry) => MapEntry(
                      entry.key,
                      Map<String, dynamic>.from(entry.value as Map),
                    ),
                  )
                      .where(
                        (entry) => (entry.value['email'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery),
                  )
                      .toList();

                  if (deliveryList.isEmpty) {
                    return const Center(
                        child: Text("No delivery persons found"));
                  }

                  return ListView.builder(
                    itemCount: deliveryList.length,
                    itemBuilder: (context, index) {
                      final deliveryId = deliveryList[index].key;
                      final deliveryData = deliveryList[index].value;

                      return Card(
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color(0xFF0288D1), width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 0),
                        child: ListTile(
                          leading: deliveryData['image'] != null && deliveryData['image'].toString().isNotEmpty
                              ? CircleAvatar(
                            backgroundImage: deliveryData['image'].toString().startsWith('data:')
                                ? MemoryImage(base64Decode(deliveryData['image'].toString().split(',').length > 1 ? deliveryData['image'].toString().split(',')[1] : ''))
                                : NetworkImage(deliveryData['image']),
                          )
                              : const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(deliveryData['name'] ?? ''),
                          subtitle: Text(deliveryData['email'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                const Icon(Icons.edit, color: Color(0xFF0288D1)),
                                onPressed: () {
                                  _editDeliveryDialog(
                                      context, deliveryId, deliveryData);
                                },
                              ),
                              IconButton(
                                icon:
                                const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _confirmDelete(context, deliveryId);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String deliveryId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Delivery Person"),
          content:
          const Text("Are you sure you want to delete this delivery person?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await dbRef.child(deliveryId).remove();
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _addDeliveryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Delivery Person"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name")),
                TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Email")),
                TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: "Phone")),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Choose Image"),
                ),
                if (_selectedImage != null)
                  Image.file(_selectedImage!,
                      height: 100, width: 100, fit: BoxFit.cover),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                try {
                  final credential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  String imageUrl = "";
                  if (_selectedImage != null) {
                    imageUrl = await _uploadImage(credential.user!.uid);
                  }

                  await dbRef.child(credential.user!.uid).set({
                    "name": nameController.text,
                    "email": emailController.text,
                    "phone": phoneController.text,
                    "image": imageUrl,
                  });

                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _editDeliveryDialog(
      BuildContext context, String deliveryId, Map deliveryData) {
    final nameController = TextEditingController(text: deliveryData['name']);
    final emailController = TextEditingController(text: deliveryData['email']);
    final phoneController = TextEditingController(text: deliveryData['phone']);
    final imageController =
    TextEditingController(text: deliveryData['image'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Delivery Person"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name")),
                TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Email")),
                TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: "Phone")),
                TextField(
                    controller: imageController,
                    decoration: const InputDecoration(labelText: "Image URL")),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: emailController.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Password reset email sent successfully")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  },
                  icon: const Icon(Icons.email),
                  label: const Text("Send Reset Password Email"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                String imageUrl = imageController.text.trim().isEmpty
                    ? (deliveryData['image'] ?? '')
                    : imageController.text.trim();

                if (_selectedImage != null) {
                  imageUrl = await _uploadImage(deliveryId);
                  _selectedImage = null;
                }

                await dbRef.child(deliveryId).update({
                  "name": nameController.text.trim(),
                  "email": emailController.text.trim(),
                  "phone": phoneController.text.trim(),
                  "image": imageUrl,
                });

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
