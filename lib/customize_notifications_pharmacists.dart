import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication library to access current user info.
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database library to read/write data.
import 'services/database_service.dart'; // Import custom DatabaseService for accessing Firebase database instance.
import 'package:flutter/material.dart'; // Import Flutter UI toolkit to build widgets.

class CustomizeNotificationsPage extends StatefulWidget { // Define a stateful widget for customizing notifications.
  const CustomizeNotificationsPage({super.key}); // Constructor with optional key.

  @override
  State<CustomizeNotificationsPage> createState() => _CustomizeNotificationsPageState();
// Create the mutable state for this widget.
}

class _CustomizeNotificationsPageState extends State<CustomizeNotificationsPage> {
  // State class that holds variables and methods for the widget.

  final FirebaseAuth _auth = FirebaseAuth.instance;
  // FirebaseAuth instance to get current logged-in pharmacist.

  final FirebaseDatabase _database = DatabaseService.instance.database;
  // FirebaseDatabase instance to read/write notification settings.

  bool newProductRequest = false; // Track whether "New Product Request" notifications are enabled.
  bool productExpirySoon = false; // Track "Product Expiry Soon" notifications.
  bool newPrescriptionsUploaded = false; // Track "New Prescriptions Uploaded" notifications.
  bool byEmail = false; // Track if notifications are sent by email.
  bool inApp = false; // Track if notifications are sent in-app.

  String? pharmacistId; // Store current pharmacist's UID.
  bool _loading = true; // Track loading state when fetching settings.
  bool _saving = false; // Track saving state when updating settings.

  DatabaseReference get _modernRef =>
      _database.ref('pharmacy_notifications/${pharmacistId ?? ''}');
  // Reference to modern per-pharmacist notification settings node.

  DatabaseReference get _legacyCollectionRef =>
      _database.ref('pharmacy/notifications');
  // Reference to legacy notification list node.

  @override
  void initState() {
    super.initState(); // Call parent initState.
    pharmacistId = _auth.currentUser?.uid;
    // Get current user's UID.
    if (pharmacistId != null) {
      _loadSettings();
      // Load existing notification settings for this pharmacist.
    } else {
      _loading = false; // Stop loading if no user logged in.
    }
  }

  Future<void> _loadSettings() async {
    // Fetch notification settings from database.
    try {
      final modernSnapshot = await _modernRef.get();
      // Get data from modern per-pharmacist node.
      if (modernSnapshot.exists) {
        _applySnapshot(modernSnapshot.value);
        // Apply settings if modern node exists.
        return;
      }

      final legacySnapshot = await _legacyCollectionRef.get();
      // If modern node doesn't exist, check legacy notifications.
      if (legacySnapshot.exists && legacySnapshot.value is Map) {
        final entries = Map<dynamic, dynamic>.from(legacySnapshot.value as Map);
        // Convert legacy snapshot to map.
        for (final entry in entries.entries) {
          final value = entry.value;
          if (value is Map && value['pharmacistId']?.toString() == pharmacistId) {
            _applySnapshot(value);
            // Apply settings if pharmacist found in legacy data.
            break;
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        // Stop loading and rebuild UI.
      }
    }
  }

  void _applySnapshot(dynamic raw) {
    // Apply fetched snapshot values to state variables.
    if (!mounted || raw is! Map) return;
    // Ensure widget is mounted and data is Map.
    setState(() {
      newProductRequest = (raw['newProductRequest'] ?? false) as bool;
      productExpirySoon = (raw['productExpirySoon'] ?? false) as bool;
      newPrescriptionsUploaded = (raw['newPrescriptionsUploaded'] ?? false) as bool;
      byEmail = (raw['byEmail'] ?? false) as bool;
      inApp = (raw['inApp'] ?? false) as bool;
    });
  }

  Future<void> _saveSettings() async {
    // Save current settings to database.
    if (pharmacistId == null) return; // Do nothing if no pharmacist logged in.
    setState(() => _saving = true); // Show saving indicator.

    final payload = {
      // Prepare data to save.
      'pharmacistId': pharmacistId,
      'newProductRequest': newProductRequest,
      'productExpirySoon': productExpirySoon,
      'newPrescriptionsUploaded': newPrescriptionsUploaded,
      'byEmail': byEmail,
      'inApp': inApp,
      'updatedAt': ServerValue.timestamp, // Store timestamp of update.
    };

    try {
      await _modernRef.set(payload);
      // Save to modern node.

      final legacySnapshot = await _legacyCollectionRef.get();
      // Check legacy collection to clean old entries.
      if (legacySnapshot.exists && legacySnapshot.value is Map) {
        final entries = Map<dynamic, dynamic>.from(legacySnapshot.value as Map);
        for (final entry in entries.entries) {
          final value = entry.value;
          if (value is Map && value['pharmacistId']?.toString() == pharmacistId) {
            await _legacyCollectionRef.child(entry.key.toString()).remove();
            // Remove old legacy entry for this pharmacist.
          }
        }
      }

      if (!mounted) return; // Check widget still exists.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings saved!')),
        // Show success message.
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e')),
        // Show error message.
      );
    } finally {
      if (mounted) setState(() => _saving = false);
      // Hide saving indicator.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customize Notifications')),
      // Top app bar with title.
      body: _loading
          ? const Center(child: CircularProgressIndicator())
      // Show loading spinner if fetching data.
          : Padding(
        padding: const EdgeInsets.all(16.0), // Add padding around content.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align items to start.
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
                // Toggle checkbox state.
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
            const Divider(height: 32), // Visual divider.
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
            const Spacer(), // Push save button to bottom.
            SizedBox(
              width: double.infinity, // Button takes full width.
              child: ElevatedButton(
                onPressed: _saving ? null : _saveSettings,
                // Disable button if saving.
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Save Changes'),
                // Show spinner if saving, otherwise button text.
              ),
            ),
          ],
        ),
      ),
    );
  }
}
