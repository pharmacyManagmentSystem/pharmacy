import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ManagePharmacistPage extends StatefulWidget {
  const ManagePharmacistPage({super.key});

  @override
  State<ManagePharmacistPage> createState() => _ManagePharmacistPageState();
}

class _ManagePharmacistPageState extends State<ManagePharmacistPage> {
  final DatabaseReference dbRef =
  DatabaseService.instance.root().child("pharmacy/pharmacists");

  List<Map<String, dynamic>> allPharmacists = [];
  List<Map<String, dynamic>> filteredPharmacists = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchPharmacists();
  }

  void fetchPharmacists() {
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
            "pharmacy_address": value["pharmacy_address"] ?? "",
          });
        });

        setState(() {
          allPharmacists = temp;
          applyFilter();
        });
      }
    });
  }

  void applyFilter() {
    if (searchQuery.isEmpty) {
      filteredPharmacists = allPharmacists;
    } else {
      filteredPharmacists = allPharmacists
          .where((pharmacist) => pharmacist["email"]
          .toLowerCase()
          .contains(searchQuery.toLowerCase()))
          .toList();
    }
  }

  /// Add or edit pharmacist
  void _showPharmacistDialog({Map<String, dynamic>? pharmacist}) {
    final nameController =
    TextEditingController(text: pharmacist?["name"] ?? "");
    final emailController =
    TextEditingController(text: pharmacist?["email"] ?? "");
    final phoneController =
    TextEditingController(text: pharmacist?["phone"] ?? "");
    final addressController =
    TextEditingController(text: pharmacist?["pharmacy_address"] ?? "");
    final passwordController = TextEditingController(); // for add OR edit

    File? pickedImage;
    String? currentImageUrl = pharmacist?["imageUrl"];

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          pickedImage = File(picked.path);
        });
      }
    }

    Future<void> savePharmacist() async {
      if (nameController.text.isEmpty ||
          emailController.text.isEmpty ||
          phoneController.text.isEmpty ||
          addressController.text.isEmpty ||
          (pharmacist == null && passwordController.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all required fields")),
        );
        return;
      }

      String? imageUrl = currentImageUrl;

      if (pickedImage != null) {
        final fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${pickedImage!.path.split('/').last}";
        final storageRef =
        FirebaseStorage.instance.ref().child("pharmacist_images/$fileName");

        await storageRef.putFile(pickedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      if (pharmacist == null) {
        // 🔹 Add new pharmacist (Auth + DB)
        try {
          UserCredential userCred = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

          String uid = userCred.user!.uid;

          await dbRef.child(uid).set({
            "id": uid,
            "uid": uid,
            "name": nameController.text,
            "email": emailController.text,
            "phone": phoneController.text,
            "imageUrl": imageUrl ?? "",
            "pharmacy_address": addressController.text,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pharmacist created successfully")),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${e.toString()}")),
          );
        }
      } else {
        // 🔹 Update pharmacist in DB
        await dbRef.child(pharmacist["id"]).update({
          "name": nameController.text,
          "email": emailController.text,
          "phone": phoneController.text,
          "imageUrl": imageUrl ?? "",
          "pharmacy_address": addressController.text,
          "uid": pharmacist["id"],
        });
      }

      Navigator.pop(context);
    }

    Future<void> updatePassword(String uid, String newPassword) async {
      try {
        await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update password: $e")),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pharmacist == null ? "Add New Pharmacist" : "Edit Pharmacist"),
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
                      ? const Icon(Icons.person, size: 40)
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
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Pharmacy Address"),
              ),
              if (pharmacist == null) ...[
                // For ADD
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
              ] else ...[
                // For EDIT → Password Change
                const SizedBox(height: 20),
                const Divider(),
                const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "New Password"),
                  obscureText: true,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (passwordController.text.isNotEmpty) {
                      updatePassword(pharmacist["id"], passwordController.text.trim());
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Enter a new password")),
                      );
                    }
                  },
                  child: const Text("Update Password"),
                ),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: savePharmacist,
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// Delete confirmation
  void _confirmDeletePharmacist(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this pharmacist?"),
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
        title: const Text("Manage Pharmacists"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showPharmacistDialog(),
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
                hintText: "Search pharmacists by email...",
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

          // Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                border: TableBorder.all(),
                columns: const [
                  DataColumn(label: Text("Email")),
                  DataColumn(label: Text("Actions")),
                ],
                rows: filteredPharmacists
                    .map(
                      (pharmacist) => DataRow(
                    cells: [
                      DataCell(Text(pharmacist["email"])),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showPharmacistDialog(pharmacist: pharmacist),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _confirmDeletePharmacist(pharmacist["id"]),
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
        onPressed: () => _showPharmacistDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
