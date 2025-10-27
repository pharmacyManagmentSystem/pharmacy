import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'services/storage_service.dart';
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

  void _showPharmacistDialog({Map<String, dynamic>? pharmacist}) {
    final nameController =
    TextEditingController(text: pharmacist?["name"] ?? "");
    final emailController =
    TextEditingController(text: pharmacist?["email"] ?? "");
    final phoneController =
    TextEditingController(text: pharmacist?["phone"] ?? "");
    final addressController =
    TextEditingController(text: pharmacist?["pharmacy_address"] ?? "");
    final passwordController = TextEditingController();

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
        final storageService = StorageService();
        imageUrl = await storageService.uploadImageToDatabase(
          pickedImage!,
          'pharmacist_images',
        );
      }

      if (pharmacist == null) {
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
        Text(pharmacist == null ? "Add New Pharmacist" : "Edit Pharmacist"),
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
                decoration:
                const InputDecoration(labelText: "Pharmacy Address"),
              ),
              if (pharmacist == null) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
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
      backgroundColor: const Color(0xFFB3E5FC), // Baby blue background
      appBar: AppBar(
        backgroundColor: Color(0xFF0288D1),
        title: const Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage("assets/pharmacy.jpg"),
              radius: 16,
            ),
            SizedBox(width: 10),
            Text(
              "Manage Pharmacists",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),

      body: Column(

        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:  Color(0xFF0288D1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Add New Pharmacy",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: () => _showPharmacistDialog(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 🔹 Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search pharmacists by email...",
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

          // 🔹 Pharmacist Cards
          Expanded(
            child: ListView.builder(
              itemCount: filteredPharmacists.length,
              itemBuilder: (context, index) {
                final pharmacist = filteredPharmacists[index];
                return Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color:  Color(0xFF0288D1), width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: pharmacist["imageUrl"].isNotEmpty
                          ? NetworkImage(pharmacist["imageUrl"])
                          : const AssetImage("assets/pharmacy.jpg")
                      as ImageProvider,
                    ),
                    title: Text(pharmacist["name"],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Email: ${pharmacist["email"]}"),
                        Text("Phone: ${pharmacist["phone"]}"),
                        Text("Address: ${pharmacist["pharmacy_address"]}"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF0288D1)),
                          onPressed: () =>
                              _showPharmacistDialog(pharmacist: pharmacist),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _confirmDeletePharmacist(pharmacist["id"]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
