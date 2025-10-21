import 'cart_item.dart';
import 'product.dart';

enum OrderStatus {
  awaitingConfirmation,
  processing,
  readyForPickup,
  outForDelivery,
  delivered,
  cancelled,
}

OrderStatus orderStatusFromString(String value) {
  switch (value) {
    case 'awaiting_confirmation':
      return OrderStatus.awaitingConfirmation;
    case 'processing':
      return OrderStatus.processing;
    case 'ready_for_pickup':
      return OrderStatus.readyForPickup;
    case 'out_for_delivery':
      return OrderStatus.outForDelivery;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.awaitingConfirmation;
  }
}

String orderStatusToString(OrderStatus status) {
  switch (status) {
    case OrderStatus.awaitingConfirmation:
      return 'awaiting_confirmation';
    case OrderStatus.processing:
      return 'processing';
    case OrderStatus.readyForPickup:
      return 'ready_for_pickup';
    case OrderStatus.outForDelivery:
      return 'out_for_delivery';
    case OrderStatus.delivered:
      return 'delivered';
    case OrderStatus.cancelled:
      return 'cancelled';
  }
}

class CustomerOrder {
  CustomerOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.address,
    this.deliveryPersonId,
    this.deliveryPersonName,
    this.notes,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String pharmacyId;
  final String pharmacyName;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final List<CartItem> items;
  final Map<String, dynamic> address;
  final String? deliveryPersonId;
  final String? deliveryPersonName;
  final String? notes;

  factory CustomerOrder.fromMap(String id, Map<dynamic, dynamic> data) {
    final itemsMap = data['items'] as Map<dynamic, dynamic>?;

    final items = itemsMap != null
        ? itemsMap.entries.map((entry) {
            final raw = Map<dynamic, dynamic>.from(entry.value as Map);

            final priceRaw = raw['price'];
            final quantityRaw = raw['quantity'];
            final expiryRaw = raw['expiryDate']?.toString();
            final expiryDate =
                expiryRaw != null && expiryRaw.isNotEmpty ? DateTime.tryParse(expiryRaw) : null;

            return CartItem(
              product: ProductPlaceholder(
                id: raw['productId']?.toString() ?? entry.key.toString(),
                name: raw['name']?.toString() ?? '',
                imageUrl: raw['imageUrl']?.toString() ?? '',
                price: priceRaw is num
                    ? priceRaw.toDouble()
                    : double.tryParse(priceRaw?.toString() ?? '0') ?? 0,
                requiresPrescription: raw['requiresPrescription'] == true,
                expiryDate: expiryDate,
              ).toProduct(),
              quantity: quantityRaw is num
                  ? quantityRaw.toInt()
                  : int.tryParse(quantityRaw?.toString() ?? '1') ?? 1,
              prescriptionUrl: raw['prescriptionUrl']?.toString(),
            );
          }).toList()
        : <CartItem>[];

    return CustomerOrder(
      id: id,
      customerId: data['customerId']?.toString() ?? '',
      customerName: data['customerName']?.toString() ?? '',
      pharmacyId: data['pharmacyId']?.toString() ?? '',
      pharmacyName: data['pharmacyName']?.toString() ?? '',
      total: data['total'] is num
          ? (data['total'] as num).toDouble()
          : double.tryParse(data['total']?.toString() ?? '0') ?? 0,
      status: orderStatusFromString(data['status']?.toString() ?? ''),
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      items: items,
      address: Map<String, dynamic>.from(data['address'] as Map? ?? {}),
      deliveryPersonId: data['deliveryPersonId']?.toString(),
      deliveryPersonName: data['deliveryPersonName']?.toString(),
      notes: data['notes']?.toString(),
    );
  }
}

class ProductPlaceholder {
  ProductPlaceholder({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.requiresPrescription,
    this.expiryDate,
  });

  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final bool requiresPrescription;
  final DateTime? expiryDate;

  Product toProduct() {
    return Product(
      id: id,
      ownerId: '',
      name: name,
      description: '',
      category: '',
      price: price,
      quantity: 0,
      imageUrl: imageUrl,
      requiresPrescription: requiresPrescription,
      expiryDate: expiryDate,
    );
  }
}
