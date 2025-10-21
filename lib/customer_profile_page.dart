import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'expiry_tracker_page.dart';
import 'models/order.dart';
import 'notification_settings_page.dart';
import 'services/database_service.dart';
import 'widgets/order_card.dart';
import 'state/customer_app_state.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key, required this.onThemeChanged});
  final ValueChanged<bool> onThemeChanged;

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  String _name = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  bool _loading = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
                const SizedBox(height: 8),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
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
                } on FirebaseAuthException catch (e) {
                  String message = 'Failed to change password.';
                  if (e.code == 'wrong-password') {
                    message = 'Old password is incorrect.';
                  }
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(message)));
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final snapshot = await DatabaseService.instance
          .ref('pharmacy/customers/${user.uid}')
          .get();

      if (!mounted) return;

      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        setState(() {
          _name = data['fullName']?.toString().trim().isEmpty ?? true
              ? 'Customer'
              : data['fullName'].toString();
          _email = data['email']?.toString() ?? user.email ?? '';
          _phone = data['phoneNumber']?.toString() ?? '';
          _address = data['address']?.toString() ?? '';
          _loading = false;
        });
      } else {
        setState(() {
          _name = 'Customer';
          _email = user.email ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _name);
    final phoneController = TextEditingController(text: _phone);
    final addressController = TextEditingController(text: _address);

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
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Update your details',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address (optional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () {
                            if (formKey.currentState?.validate() ?? false) {
                              Navigator.pop(context, true);
                            }
                          },
                          child: const Text('Save changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (shouldSave != true) return;

    try {
      await DatabaseService.instance
          .ref('pharmacy/customers/${user.uid}')
          .update({
        'fullName': nameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'address': addressController.text.trim(),
      });

      if (!mounted) return;

      setState(() {
        _name = nameController.text.trim();
        _phone = phoneController.text.trim();
        _address = addressController.text.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final appState = context.watch<CustomerAppState>();

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            name: _name,
            email: _email,
            phone: _phone,
            address: _address,
            onEditTap: _editProfile,
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Preferences'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() => _darkMode = value);
                    widget.onThemeChanged(value);
                  },
                  title: const Text('Dark mode'),
                  subtitle: Text(
                    _darkMode
                        ? 'App is currently using the dark theme.'
                        : 'Tap to switch to the dark theme.',
                  ),
                  secondary: const Icon(Icons.dark_mode_outlined),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Customize notifications'),
                  subtitle: const Text('Choose how pharmacists reach out to you.'),
                  onTap: () async {
                    final updated = await Navigator.push<NotificationPreferences>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationSettingsPage(
                          initialPreferences: appState.notificationPreferences,
                        ),
                      ),
                    );
                    if (updated != null) {
                      appState.updateNotificationPreferences(updated);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Quick actions'),
          _ActionCard(
            icon: Icons.calendar_month_outlined,
            title: 'Check soon expiry dates',
            subtitle: 'Review items that are about to expire.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpiryTrackerPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.local_shipping_outlined,
            title: 'Track orders',
            subtitle: 'See the status of your recent orders.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersHistoryPage()),
              );
            },
          ),

          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _showChangePasswordDialog,
            child: const Text("Change Password"),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.onEditTap,
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.blue ,
                  child: Icon(
                    Icons.person_outline,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(email, style: theme.textTheme.bodyMedium),
                      if (phone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(phone, style: theme.textTheme.bodyMedium),
                        ),
                      if (address.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_pin, size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  address,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
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
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
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

class OrdersHistoryPage extends StatelessWidget {
  const OrdersHistoryPage({super.key});

  Stream<List<CustomerOrder>> _ordersStream(String userId) {
    final ref = DatabaseService.instance.ref('customer_orders/');
    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data is! Map) return <CustomerOrder>[];
      return data.entries
          .map<CustomerOrder>((entry) => CustomerOrder.fromMap(
                entry.key.toString(),
                Map<dynamic, dynamic>.from(entry.value as Map),
              ))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your orders.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Order history')),
      body: StreamBuilder<List<CustomerOrder>>(
        stream: _ordersStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load orders.'));
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('You have not placed any orders yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}






