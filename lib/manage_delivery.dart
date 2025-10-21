import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
    final ref = FirebaseStorage.instance.ref().child('pharmacy/delivery_persons/$uid.jpg');
    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Delivery")),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search by Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // 📋 Delivery table
          Expanded(
            child: StreamBuilder(
              stream: dbRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading data"));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text("No delivery persons found"));
                }

                final event = snapshot.data! as DatabaseEvent;
                final raw = event.snapshot.value;

                if (raw is! Map<dynamic, dynamic>) {
                  return const Center(child: Text("No delivery persons found"));
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
                      (entry) =>
                          (entry.value['email'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(searchQuery),
                    )
                    .toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Email")),
                      DataColumn(label: Text("Actions")),
                    ],
                    rows: deliveryList.map((entry) {
                      final deliveryId = entry.key;
                      final deliveryData = entry.value;

                      return DataRow(
                        cells: [
                          DataCell(Text(deliveryData["email"] ?? "")),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _editDeliveryDialog(
                                      context, deliveryId, deliveryData);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _confirmDelete(context, deliveryId);
                                },
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ➕ Add delivery person
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDeliveryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 🗑 Confirm delete
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

  // ➕ Add delivery
  void _addDeliveryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final imageController = TextEditingController();
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
                // زر اختيار صورة
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Choose Image"),
                ),
                if (_selectedImage != null)
                  Image.file(_selectedImage!, height: 100, width: 100, fit: BoxFit.cover),


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
                  // ➕ Create user in Firebase Auth
                  final credential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  String imageUrl = "";
                  if (_selectedImage != null) {
                    imageUrl = await _uploadImage(credential.user!.uid);
                  }

// حفظ البيانات
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

  // ✏️ Edit delivery
  void _editDeliveryDialog(
      BuildContext context, String deliveryId, Map deliveryData) {
    final nameController =
    TextEditingController(text: deliveryData['name']);
    final emailController =
    TextEditingController(text: deliveryData['email']);
    final phoneController =
    TextEditingController(text: deliveryData['phone']);
    final imageController =
    TextEditingController(text: deliveryData['image']);

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
                    decoration:
                    const InputDecoration(labelText: "Image URL")),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: emailController.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text("Password reset email sent successfully")),
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
                // ✅ Update DB
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

