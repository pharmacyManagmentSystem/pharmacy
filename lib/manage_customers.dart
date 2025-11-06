import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

class ManageCustomersPage extends StatefulWidget {
  const ManageCustomersPage({super.key});

  @override
  State<ManageCustomersPage> createState() => _ManageCustomersPageState();
}

class _ManageCustomersPageState extends State<ManageCustomersPage> {
  final DatabaseReference dbRef =
  DatabaseService.instance.root().child("pharmacy/customers");

  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void fetchUsers() {
    dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        List<Map<String, dynamic>> temp = [];
        data.forEach((key, value) {
          temp.add({
            "id": key,
            "name": value["name"] ?? "Unknown",
            "email": value["email"] ?? "",
            "phone": value["phone"] ?? "",
            "imageUrl": value["imageUrl"] ?? "",
            "status": value["status"] ?? "active",
          });
        });
        setState(() {
          allUsers = temp;
          applyFilter();
        });
      }
    });
  }

  void applyFilter() {
    if (searchQuery.isEmpty) {
      filteredUsers = allUsers;
    } else {
      filteredUsers = allUsers
          .where((user) =>
          user["email"].toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
  }

  void _showUserDialog({required Map<String, dynamic> user}) {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user["name"] ?? "");
    final emailController = TextEditingController(text: user["email"] ?? "");
    final phoneController = TextEditingController(text: user["phone"] ?? "");
    File? pickedImage;
    String? currentImageUrl = user["imageUrl"];

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          pickedImage = File(picked.path);
        });
      }
    }

    Future<void> saveUser() async {
      if (!_formKey.currentState!.validate()) return;

      String? imageUrl = currentImageUrl;
      if (pickedImage != null) {
        final storageService = StorageService();
        imageUrl = await storageService.uploadImageToDatabase(
          pickedImage!,
          'customer_images',
        );
      }

      await dbRef.child(user["id"]).update({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "imageUrl": imageUrl ?? "",
        "uid": user["id"],
        "status": user["status"] ?? "active",
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer updated successfully")),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Customer"),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: pickedImage != null
                        ? FileImage(pickedImage!)
                        : (currentImageUrl != null &&
                        currentImageUrl.isNotEmpty)
                        ? NetworkImage(currentImageUrl) as ImageProvider
                        : null,
                    child: (pickedImage == null &&
                        (currentImageUrl == null ||
                            currentImageUrl.isEmpty))
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
                        .hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone is required';
                    }
                    if (!RegExp(r'^[97]\d{7}$').hasMatch(value)) {
                      return 'Must start with 9 or 7 and be 8 digits long';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: saveUser,
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(String id, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Account Status"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select new status for this account:"),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Active"),
              subtitle: const Text("User can log in and use the platform"),
              leading: Radio<String>(
                value: "active",
                groupValue: currentStatus,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateStatus(id, value!);
                },
              ),
            ),
            ListTile(
              title: const Text("Suspended"),
              subtitle: const Text("Account is temporarily disabled"),
              leading: Radio<String>(
                value: "suspended",
                groupValue: currentStatus,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateStatus(id, value!);
                },
              ),
            ),
            ListTile(
              title: const Text("Deleted"),
              subtitle: const Text("Account is inactive but kept for records"),
              leading: Radio<String>(
                value: "deleted",
                groupValue: currentStatus,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateStatus(id, value!);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    await dbRef.child(id).update({"status": newStatus});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Account status updated to $newStatus")),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "active":
        return Colors.green;
      case "suspended":
        return Colors.orange;
      case "deleted":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3E5FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0288D1),
        title: const Row(
          children: [
            Icon(Icons.people, color: Colors.white),
            SizedBox(width: 10),
            Text("Manage Customers", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search customers by email...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                  applyFilter();
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border:
                      Border.all(color: const Color(0xFF0288D1), width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (user["imageUrl"] != null &&
                              user["imageUrl"].isNotEmpty)
                              ? (user["imageUrl"].toString().startsWith('data:')
                              ? MemoryImage(base64Decode(
                              user["imageUrl"]
                                  .toString()
                                  .split(',')[1]))
                              : NetworkImage(user["imageUrl"]))
                          as ImageProvider
                              : null,
                          child: (user["imageUrl"] == null ||
                              user["imageUrl"].isEmpty)
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(user["name"]),
                        subtitle: Text(user["email"]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                _getStatusColor(user["status"] ?? "active"),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (user["status"] ?? "active")
                                    .toString()
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFF0288D1)),
                              onPressed: () => _showUserDialog(user: user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline,
                                  color: Colors.orange),
                              onPressed: () => _showStatusDialog(
                                  user["id"], user["status"] ?? "active"),
                              tooltip: "Change account status",
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
