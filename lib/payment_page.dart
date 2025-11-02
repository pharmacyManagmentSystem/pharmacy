import 'package:firebase_auth/firebase_auth.dart';
import 'services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      
      // تحقق محدث من حالة الموافقة لكل منتج في السلة
      bool hasPendingItems = false;
      
      for (var item in state.cartItems) {
        if (item.pendingApproval && item.requestId != null) {
          // تحقق مباشر من قاعدة البيانات
          final snapshot = await DatabaseService.instance
              .customerCartRef(user.uid)
              .child(item.requestId!)
              .get();
              
          if (snapshot.exists && snapshot.value is Map) {
            final data = snapshot.value as Map;
            if (data['approved'] == true || data['status'] == 'approved' || data['pendingApproval'] == false) {
              // تم الموافقة على هذا المنتج - تحديث الحالة المحلية
              item.pendingApproval = false;
              continue;
            }
          }
          hasPendingItems = true;
          break;
        }
      }
      
      if (hasPendingItems) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('في انتظار الموافقة'),
            content: const Text('بعض المنتجات في سلتك تحتاج إلى موافقة الصيدلي. لا يمكن إتمام الدفع حتى تتم الموافقة.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('حسناً')
              ),
            ],
          ),
        );
        return;
      }
      final hasRejected = state.cartItems.any((i) => i.rejected);
      if (hasRejected) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Item rejected'),
            content: const Text('One or more items in your cart were rejected by the pharmacist and cannot be purchased.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
        return;
      }
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
  void dispose() {
    _name.dispose();
    _card.dispose();
    _cvv.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Regex: only Latin letters and spaces
    final nameReg = RegExp(r'^[A-Za-z ]+$');

    return Scaffold(
      appBar: AppBar(title: const Text('Payment details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
              inputFormatters: [
                // Allow only Latin letters and space while typing
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z\s]')),
                LengthLimitingTextInputFormatter(50),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter name';
                if (!nameReg.hasMatch(v.trim())) return 'Name must contain only letters and spaces';
                return null;
              },
              // hide built-in counter
              buildCounter: (
                  BuildContext context, {
                    required int currentLength,
                    required bool isFocused,
                    required int? maxLength,
                  }) =>
              null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _card,
              decoration: const InputDecoration(labelText: 'Card number'),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16), // prevent more than 16 digits
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter card number';
                if (v.length != 16) return 'Card number must be exactly 16 digits';
                final cardReg = RegExp(r'^\d{16}$');
                if (!cardReg.hasMatch(v)) return 'Card number must contain only digits';
                return null;
              },
              buildCounter: (
                  BuildContext context, {
                    required int currentLength,
                    required bool isFocused,
                    required int? maxLength,
                  }) =>
              null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cvv,
              decoration: const InputDecoration(labelText: 'CVV'),
              keyboardType: TextInputType.number,
              obscureText: true,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3), // prevent more than 3 digits
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter CVV';
                if (v.length != 3) return 'CVV must be exactly 3 digits';
                final cvvReg = RegExp(r'^\d{3}$');
                if (!cvvReg.hasMatch(v)) return 'CVV must contain only digits';
                return null;
              },
              buildCounter: (
                  BuildContext context, {
                    required int currentLength,
                    required bool isFocused,
                    required int? maxLength,
                  }) =>
              null,
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
