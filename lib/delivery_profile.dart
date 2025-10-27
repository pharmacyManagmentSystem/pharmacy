import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'services/database_service.dart';

class DeliveryPersonProfilePage extends StatefulWidget {
  const DeliveryPersonProfilePage({
    super.key,
    required this.onThemeChanged,
  });

  final ValueChanged<bool> onThemeChanged;

  @override
  State<DeliveryPersonProfilePage> createState() =>
      _DeliveryPersonProfilePageState();
}

class _DeliveryPersonProfilePageState
    extends State<DeliveryPersonProfilePage> {
  String _name = '';
  String _email = '';
  String _phone = '';
  bool _loading = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final snapshot = await DatabaseService.instance
          .ref('pharmacy/delivery_persons/${user.uid}')
          .get();

      if (!mounted) return;

      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        setState(() {
          _name = data['fullName']?.toString().trim().isEmpty ?? true
              ? 'Delivery Person'
              : data['fullName'].toString();
          _email = data['email']?.toString() ?? user.email ?? '';
          _phone = data['phoneNumber']?.toString() ?? '';
          _darkMode = data['darkMode'] ?? false;
          _loading = false;
        });
      } else {
        setState(() {
          _name = 'Delivery Person';
          _email = user.email ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ Updated Change Password Method
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
                const SizedBox(height: 8),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmPasswordController,
                  decoration:
                  const InputDecoration(labelText: 'Repeat New Password'),
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

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                  return;
                }

                final passwordRegex = RegExp(
                    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{6,}$');
                if (!passwordRegex.hasMatch(newPassword)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Password must be at least 6 characters and include upper, lower, number, and symbol.'),
                    ),
                  );
                  return;
                }

                try {
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: oldPassword,
                  );
                  await user.reauthenticateWithCredential(credential);

                  // Update in Firebase Auth
                  await user.updatePassword(newPassword);

                  // ✅ Update password in Firebase Realtime Database
                  await DatabaseService.instance
                      .ref('pharmacy/delivery_persons/${user.uid}')
                      .update({'password': newPassword});

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password changed successfully')),
                  );
                  Navigator.pop(context);
                } on FirebaseAuthException catch (e) {
                  String message = 'Failed to change password.';
                  if (e.code == 'wrong-password') {
                    message = 'Old password is incorrect.';
                  }
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Person Profile'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileHeader(
              name: _name,
              email: _email,
              phone: _phone,
              onEditTap: _editProfile,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Preferences'),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _darkMode,
                    onChanged: (value) async {
                      setState(() => _darkMode = value);
                      widget.onThemeChanged(value);

                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await DatabaseService.instance
                            .ref('pharmacy/delivery_persons/${user.uid}')
                            .update({'darkMode': value});
                      }
                    },
                    title: const Text('Dark mode'),
                    subtitle: Text(
                      _darkMode
                          ? 'App is currently using the dark theme.'
                          : 'Tap to switch to the dark theme.',
                    ),
                    secondary: const Icon(Icons.dark_mode_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Quick actions'),
            ElevatedButton(
              onPressed: _showChangePasswordDialog,
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: _name);
    final phoneController = TextEditingController(text: _phone);

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration:
                  const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Save changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldSave != true) return;

    try {
      await DatabaseService.instance
          .ref('pharmacy/delivery_persons/${user.uid}')
          .update({
        'fullName': nameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
      });

      if (!mounted) return;

      setState(() {
        _name = nameController.text.trim();
        _phone = phoneController.text.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.phone,
    required this.onEditTap,
  });

  final String name;
  final String email;
  final String phone;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person_outline,
                  size: 40, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(email, style: theme.textTheme.bodyMedium),
                  if (phone.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(phone, style: theme.textTheme.bodyMedium),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEditTap,
              tooltip: 'Edit profile',
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      ),
    );
  }
}
