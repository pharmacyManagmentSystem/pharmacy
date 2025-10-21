import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'customize_notifications_pharmacists.dart';
import 'pharmacist_requests_page.dart';
import 'pharmacist_prescriptions_page.dart';

class ProfilePage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const ProfilePage({super.key, required this.onThemeChanged});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isDarkMode = false;
  String pharmacyName = '';
  String email = '';
  String phone = '';
  String address = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPharmacistData();
  }


  void _showChangePasswordDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  decoration: const InputDecoration(labelText: 'Old Password'),
                  obscureText: true,
                ),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                ),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Repeat New Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final oldPassword = oldPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                // Check if new password matches confirm password
                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                  return;
                }

                // Strong password validation
                final passwordRegex =
                RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{6,}$');

                if (!passwordRegex.hasMatch(newPassword)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Password must be at least 6 characters, include upper & lower case letters, a number, and a special character'),
                    ),
                  );
                  return;
                }

                try {
                  // Re-authenticate user
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: oldPassword,
                  );
                  await user.reauthenticateWithCredential(credential);

                  // Update password
                  await user.updatePassword(newPassword);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }




  Future<void> fetchPharmacistData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DatabaseReference ref =
        DatabaseService.instance.ref('pharmacy/pharmacists/${user.uid}');
        DataSnapshot snapshot = await ref.get();

        if (snapshot.exists) {
          setState(() {
            pharmacyName = snapshot.child('name').value?.toString() ?? 'No Name';
            email = snapshot.child('email').value?.toString() ?? 'No Email';
            phone = snapshot.child('phone').value?.toString() ?? '';
            address = snapshot.child('pharmacy_address').value?.toString() ?? '';
            isLoading = false;
          });
        } else {
          setState(() {
            pharmacyName = 'No Data Found';
            email = '';
            phone = '';
            address = '';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          pharmacyName = 'Not Signed In';
          email = '';
          phone = '';
          address = '';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        pharmacyName = 'Error loading data';
        email = '';
        phone = '';
        address = '';
        isLoading = false;
      });
    }
  }


  void _showEditProfileDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: pharmacyName);
    final phoneController = TextEditingController(text: phone);
    final addressController = TextEditingController(text: address);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Pharmacy name'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone number'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updates = {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'pharmacy_address': addressController.text.trim(),
                };

                await DatabaseService.instance.ref('pharmacy/pharmacists/${user.uid}')
                    .update(updates);

                setState(() {
                  pharmacyName = updates['name'] ?? pharmacyName;
                  phone = updates['phone'] ?? phone;
                  address = updates['pharmacy_address'] ?? address;
                });

                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save changes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.black26,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 10),
            Text(
              pharmacyName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(email),
            if (phone.isNotEmpty) Text(phone),
            if (address.isNotEmpty) Text(address),
            const Divider(thickness: 1),
            const SizedBox(height: 10),

            // Buttons
            ElevatedButton(
              onPressed: _showEditProfileDialog,
              child: const Text("Edit Profile"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Check soon expiry dates"),
            ),
            const SizedBox(height: 10),

            // Dark Mode Switch
            SwitchListTile(
              title: const Text("Turn On Dark Mode"),
              value: isDarkMode,
              onChanged: (val) {
                setState(() {
                  isDarkMode = val;
                });
                widget.onThemeChanged(val); // Notify parent to change theme
              },
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PharmacistRequestsPage(pharmacyId: user.uid),
                  ),
                );
              },
              child: const Text("Check Requested Products"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PharmacistPrescriptionsPage(pharmacyId: user.uid),
                  ),
                );
              },
              child: const Text('View Uploaded Prescription'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const CustomizeNotificationsPage(),
                  ),
                );
              },
              child: const Text("Customize Notifications"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _showChangePasswordDialog,
              child: const Text("Change Password"),
            ),

          ],
        ),
      ),
    );
  }
}
