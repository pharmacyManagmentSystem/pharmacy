import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  /// Dialog لإضافة أو تعديل مستخدم
  void _showUserDialog({Map<String, dynamic>? user}) {
    final nameController = TextEditingController(text: user?["name"] ?? "");
    final emailController = TextEditingController(text: user?["email"] ?? "");
    final phoneController = TextEditingController(text: user?["phone"] ?? "");
    File? pickedImage;
    String? currentImageUrl = user?["imageUrl"];

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
      if (nameController.text.isEmpty ||
          emailController.text.isEmpty ||
          phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields")),
        );
        return;
      }

      String? imageUrl = currentImageUrl;

      if (pickedImage != null) {
        final fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${pickedImage!.path.split('/').last}";
        final storageRef =
        FirebaseStorage.instance.ref().child("customer_images/$fileName");

        await storageRef.putFile(pickedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      if (user == null) {
        // إضافة
        String newId = dbRef.push().key!;
        await dbRef.child(newId).set({
          "name": nameController.text,
          "email": emailController.text,
          "phone": phoneController.text,
          "imageUrl": imageUrl ?? "",
        });
      } else {
        // تعديل
        await dbRef.child(user["id"]).update({
          "name": nameController.text,
          "email": emailController.text,
          "phone": phoneController.text,
          "imageUrl": imageUrl ?? "",
        });
      }

      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? "Add New Customer" : "Edit Customer"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: pickedImage != null
                      ? FileImage(pickedImage!)
                      : (currentImageUrl != null && currentImageUrl.isNotEmpty)
                      ? NetworkImage(currentImageUrl) as ImageProvider
                      : null,
                  child: (pickedImage == null &&
                      (currentImageUrl == null || currentImageUrl.isEmpty))
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
              ),
            ],
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

  /// حذف مستخدم مع رسالة تأكيد
  void _confirmDeleteUser(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this user??"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await dbRef.child(id).remove();
              Navigator.pop(context);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Customers"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showUserDialog(),
          )
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search customers by email...",
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

          // Table of users
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                border: TableBorder.all(),
                columns: const [
                  DataColumn(label: Text("Email")),
                  DataColumn(label: Text("Actions")),
                ],
                rows: filteredUsers
                    .map(
                      (user) => DataRow(
                    cells: [
                      DataCell(Text(user["email"])),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showUserDialog(user: user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () => _confirmDeleteUser(user["id"]),
                          ),
                        ],
                      )),
                    ],
                  ),
                )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
