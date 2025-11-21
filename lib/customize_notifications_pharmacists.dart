import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'package:flutter/material.dart';

class CustomizeNotificationsPage extends StatefulWidget {
  const CustomizeNotificationsPage({super.key});

  @override
  State<CustomizeNotificationsPage> createState() =>
      _CustomizeNotificationsPageState();
}

class _CustomizeNotificationsPageState
    extends State<CustomizeNotificationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = DatabaseService.instance.database;

  bool newProductRequest = false;
  bool productExpirySoon = false;
  bool newPrescriptionsUploaded = false;
  bool byEmail = false;
  bool inApp = false;

  String? pharmacistId;
  bool _loading = true;
  bool _saving = false;

  DatabaseReference get _modernRef =>
      _database.ref('pharmacy_notifications/${pharmacistId ?? ''}');

  DatabaseReference get _legacyCollectionRef =>
      _database.ref('pharmacy/notifications');

  @override
  void initState() {
    super.initState();
    pharmacistId = _auth.currentUser?.uid;
    if (pharmacistId != null) {
      _loadSettings();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadSettings() async {
    try {
      final modernSnapshot = await _modernRef.get();
      if (modernSnapshot.exists) {
        _applySnapshot(modernSnapshot.value);
        return;
      }

      final legacySnapshot = await _legacyCollectionRef.get();
      if (legacySnapshot.exists && legacySnapshot.value is Map) {
        final entries = Map<dynamic, dynamic>.from(legacySnapshot.value as Map);
        for (final entry in entries.entries) {
          final value = entry.value;
          if (value is Map &&
              value['pharmacistId']?.toString() == pharmacistId) {
            _applySnapshot(value);
            break;
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _applySnapshot(dynamic raw) {
    if (!mounted || raw is! Map) return;
    setState(() {
      newProductRequest = (raw['newProductRequest'] ?? false) as bool;
      productExpirySoon = (raw['productExpirySoon'] ?? false) as bool;
      newPrescriptionsUploaded =
          (raw['newPrescriptionsUploaded'] ?? false) as bool;
      byEmail = (raw['byEmail'] ?? false) as bool;
      inApp = (raw['inApp'] ?? false) as bool;
    });
  }

  Future<void> _saveSettings() async {
    if (pharmacistId == null) return;
    setState(() => _saving = true);

    final payload = {
      'pharmacistId': pharmacistId,
      'newProductRequest': newProductRequest,
      'productExpirySoon': productExpirySoon,
      'newPrescriptionsUploaded': newPrescriptionsUploaded,
      'byEmail': byEmail,
      'inApp': inApp,
      'updatedAt': ServerValue.timestamp,
    };

    try {
      await _modernRef.set(payload);

      final legacySnapshot = await _legacyCollectionRef.get();
      if (legacySnapshot.exists && legacySnapshot.value is Map) {
        final entries = Map<dynamic, dynamic>.from(legacySnapshot.value as Map);
        for (final entry in entries.entries) {
          final value = entry.value;
          if (value is Map &&
              value['pharmacistId']?.toString() == pharmacistId) {
            await _legacyCollectionRef.child(entry.key.toString()).remove();
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings saved!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customize Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notification Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  CheckboxListTile(
                    title: const Text('New Product Request'),
                    value: newProductRequest,
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => newProductRequest = val);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Product Expiry Soon'),
                    value: productExpirySoon,
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => productExpirySoon = val);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('New Prescriptions Uploaded'),
                    value: newPrescriptionsUploaded,
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => newPrescriptionsUploaded = val);
                    },
                  ),
                  const Divider(height: 32),
                  const Text(
                    'How would you like to receive notifications?',
                    style: TextStyle(fontSize: 16),
                  ),
                  CheckboxListTile(
                    title: const Text('By Email'),
                    value: byEmail,
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => byEmail = val);
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('In-App Notification'),
                    value: inApp,
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => inApp = val);
                    },
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50)),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
