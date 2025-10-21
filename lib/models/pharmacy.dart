class PharmacySummary {
  const PharmacySummary({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.address,
    required this.imageUrl,
    this.phone,
  });

  final String id;
  final String uid;
  final String name;
  final String email;
  final String address;
  final String imageUrl;
  final String? phone;

  factory PharmacySummary.fromMap(String id, Map<dynamic, dynamic> data) {
    final uid = (data['uid'] ?? data['id'] ?? id).toString();
    return PharmacySummary(
      id: (data['customId'] ?? data['pharmacyId'] ?? id).toString(),
      uid: uid,
      name: (data['name'] ?? data['fullName'] ?? 'Pharmacy') as String,
      email: (data['email'] ?? '') as String,
      address: (data['pharmacy_address'] ?? data['address'] ?? 'No address provided')
          as String,
      imageUrl: (data['imageUrl'] ?? data['profileImage'] ?? '') as String,
      phone: data['phone']?.toString(),
    );
  }
}
