import 'package:firebase_auth/firebase_auth.dart';
import 'services/database_service.dart';
import 'package:flutter/material.dart';

import 'state/customer_app_state.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key, required this.initialPreferences});

  final NotificationPreferences initialPreferences;

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late NotificationPreferences _preferences;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _preferences = NotificationPreferences(
      newProductRequest: widget.initialPreferences.newProductRequest,
      productExpiry: widget.initialPreferences.productExpiry,
      prescriptionUploaded: widget.initialPreferences.prescriptionUploaded,
      email: widget.initialPreferences.email,
      inApp: widget.initialPreferences.inApp,
    );
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await DatabaseService.instance.ref('pharmacy/customer_notifications/${user.uid}')
          .set(_preferences.toMap());
      if (!mounted) return;
      Navigator.pop(context, _preferences);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save preferences: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Customize settings', style: TextStyle(fontWeight: FontWeight.bold)),
          SwitchListTile(
            value: _preferences.newProductRequest,
            onChanged: (value) => setState(() => _preferences.newProductRequest = value),
            title: const Text('New product requests'),
          ),
          SwitchListTile(
            value: _preferences.productExpiry,
            onChanged: (value) => setState(() => _preferences.productExpiry = value),
            title: const Text('Product expiry reminders'),
          ),
          SwitchListTile(
            value: _preferences.prescriptionUploaded,
            onChanged: (value) => setState(() => _preferences.prescriptionUploaded = value),
            title: const Text('Prescription updates'),
          ),
          const Divider(),
          const Text('Delivery method', style: TextStyle(fontWeight: FontWeight.bold)),
          SwitchListTile(
            value: _preferences.email,
            onChanged: (value) => setState(() => _preferences.email = value),
            title: const Text('Email notifications'),
          ),
          SwitchListTile(
            value: _preferences.inApp,
            onChanged: (value) => setState(() => _preferences.inApp = value),
            title: const Text('In-app notifications'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save settings'),
            ),
          ),
        ],
      ),
    );
  }
}
