import 'package:firebase_auth/firebase_auth.dart';
import 'services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/customer_app_state.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.pharmacyId, required this.pharmacyName});
  final String pharmacyId;
  final String pharmacyName;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _card = TextEditingController();
  final TextEditingController _cvv = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerName();
  }

  Future<void> _loadCustomerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap =
    await DatabaseService.instance.ref('pharmacy/customers/${user.uid}').get();
    if (snap.exists && snap.value is Map) {
      final data = snap.value as Map;
      _name.text = data['fullName'] ?? data['name'] ?? '';
    }
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final state = context.read<CustomerAppState>();
      final orderId = await state.submitOrder(
        customerId: user.uid,
        customerName: _name.text.trim(),
        customerEmail: user.email ?? '',
        pharmacyId: widget.pharmacyId,
        pharmacyName: widget.pharmacyName,
        paymentMethod: 'card',
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Order $orderId placed successfully.')));
      Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _card,
              decoration: const InputDecoration(labelText: 'Card number'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.length < 12 ? 'Invalid card' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cvv,
              decoration: const InputDecoration(labelText: 'CVV'),
              keyboardType: TextInputType.number,
              obscureText: true,
              validator: (v) => v == null || v.length < 3 ? 'Invalid CVV' : null,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _submit(context),
                child: _loading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Pay now'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
