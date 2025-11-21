import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'state/customer_app_state.dart';
import 'payment_page.dart';

class LocationCapturePage extends StatefulWidget {
  const LocationCapturePage(
      {super.key, required this.pharmacyId, required this.pharmacyName});

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
  final MapController _mapController = MapController();

  LatLng _selectedLocation =
  const LatLng(23.6100, 58.5400); // Default to Muscat, Oman
  bool _showMap = false;

  @override
  void dispose() {
    _houseController.dispose();
    _roadController.dispose();
    _tipsController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _mapController.move(location, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery location')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select your delivery location on the map:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showMap = !_showMap;
                    });
                  },
                  icon: Icon(_showMap ? Icons.map : Icons.map_outlined),
                  label: Text(_showMap ? 'Hide Map' : 'Show Map'),
                ),
                const SizedBox(height: 12),

                if (_showMap)
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedLocation,
                          initialZoom: 15.0,
                          onTap: _onMapTap,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.pharm',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation,
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 50,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_showMap) const SizedBox(height: 16),

                TextFormField(
                  controller: _houseController,
                  decoration: const InputDecoration(
                    labelText: 'House / Building number',
                    prefixIcon: Icon(Icons.home),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter your house or building number'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _roadController,
                  decoration: const InputDecoration(
                    labelText: 'Road number',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter the road number'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tipsController,
                  decoration: const InputDecoration(
                    labelText: 'Directions for delivery (optional)',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final address = CustomerShippingAddress(
                          houseNumber: _houseController.text.trim(),
                          roadNumber: _roadController.text.trim(),
                          additionalDirections: _tipsController.text.trim(),
                          latitude: _selectedLocation.latitude,
                          longitude: _selectedLocation.longitude,
                        );
                        context
                            .read<CustomerAppState>()
                            .setShippingAddress(address);
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'Continue to payment',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
