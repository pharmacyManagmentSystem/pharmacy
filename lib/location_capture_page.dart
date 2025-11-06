import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/customer_app_state.dart';
import 'payment_page.dart';

class LocationCapturePage extends StatefulWidget {
  const LocationCapturePage({super.key, required this.pharmacyId, required this.pharmacyName});

  final String pharmacyId;
  final String pharmacyName;

  @override
  State<LocationCapturePage> createState() => _LocationCapturePageState();
}

class _LocationCapturePageState extends State<LocationCapturePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _roadController = TextEditingController();
  final TextEditingController _tipsController = TextEditingController();

  @override
  void dispose() {
    _houseController.dispose();
    _roadController.dispose();
    _tipsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery location')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your delivery details'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _houseController,
                decoration: const InputDecoration(labelText: 'House / Building number'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter your house or building number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roadController,
                decoration: const InputDecoration(labelText: 'Road number'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter the road number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tipsController,
                decoration: const InputDecoration(labelText: 'Directions for delivery (optional)'),
                maxLines: 3,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final address = CustomerShippingAddress(
                        houseNumber: _houseController.text.trim(),
                        roadNumber: _roadController.text.trim(),
                        additionalDirections: _tipsController.text.trim(),
                      );
                      context.read<CustomerAppState>().setShippingAddress(address);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(
                            pharmacyId: widget.pharmacyId,
                            pharmacyName: widget.pharmacyName,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Continue to payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
