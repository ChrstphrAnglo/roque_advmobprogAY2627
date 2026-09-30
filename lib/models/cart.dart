double _round2(double value) => (value * 100).round() / 100;

class Cart {
  final int id;
  final List<CartProduct> products;
  final double total;
  final double discountedTotal;
  final int userId;
  final int totalProducts;
  final int totalQuantity;

  Cart({
    required this.id,
    required this.products,
    required this.total,
    required this.discountedTotal,
    required this.userId,
    required this.totalProducts,
    required this.totalQuantity,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? 0,
      products: (json['products'] as List?)
              ?.map((e) => CartProduct.fromJson(e))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountedTotal: (json['discountedTotal'] as num?)?.toDouble() ?? 0.0,
      userId: json['userId'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalQuantity: json['totalQuantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'products': products.map((e) => e.toJson()).toList(),
      'total': total,
      'discountedTotal': discountedTotal,
      'userId': userId,
      'totalProducts': totalProducts,
      'totalQuantity': totalQuantity,
    };
  }

  /// A cart with no items, used when the API has no cart for the user.
  factory Cart.empty(int userId) => Cart(
        id: 0,
        products: const [],
        total: 0,
        discountedTotal: 0,
        userId: userId,
        totalProducts: 0,
        totalQuantity: 0,
      );

  bool get isEmpty => products.isEmpty;

  /// The same cart with [items] swapped in and every total recalculated.
  Cart withProducts(List<CartProduct> items) {
    return Cart(
      id: id,
      products: items,
      total: _round2(items.fold(0.0, (sum, e) => sum + e.total)),
      discountedTotal: _round2(items.fold(0.0, (sum, e) => sum + e.discountedTotal)),
      userId: userId,
      totalProducts: items.length,
      totalQuantity: items.fold(0, (sum, e) => sum + e.quantity),
    );
  }
}

class CartProduct {
  final int id;
  final String title;
  final double price;
  final int quantity;
  final double total;
  final double discountPercentage;
  final double discountedTotal;
  final String thumbnail;

  CartProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    required this.total,
    required this.discountPercentage,
    required this.discountedTotal,
    required this.thumbnail,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      // POST /carts/add names this field "discountedPrice" instead of "discountedTotal".
      discountedTotal: ((json['discountedTotal'] ?? json['discountedPrice']) as num?)
              ?.toDouble() ??
          0.0,
      thumbnail: json['thumbnail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'quantity': quantity,
      'total': total,
      'discountPercentage': discountPercentage,
      'discountedTotal': discountedTotal,
      'thumbnail': thumbnail,
    };
  }

  /// Same product at a new quantity, with its totals recalculated.
  CartProduct withQuantity(int newQuantity) {
    final newTotal = _round2(price * newQuantity);
    return CartProduct(
      id: id,
      title: title,
      price: price,
      quantity: newQuantity,
      total: newTotal,
      discountPercentage: discountPercentage,
      discountedTotal: _round2(newTotal * (1 - discountPercentage / 100)),
      thumbnail: thumbnail,
    );
  }
}
