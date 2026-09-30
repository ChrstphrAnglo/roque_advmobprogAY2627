import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';

class CartService {
  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  // Enhancement 3: get one cart by its own id -> GET /carts/{id}
  Future<Cart> getCartById(int id) async {
    final response = await http.get(Uri.parse('$host/carts/$id'));

    if (response.statusCode == 200) {
      return Cart.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load cart $id');
  }

  // Enhancement 3: get the cart that belongs to one user -> GET /carts/user/{userId}
  // Returns null when the user has no cart.
  Future<Cart?> getCartByUserId(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      if (cartsJson.isEmpty) return null;
      return Cart.fromJson(cartsJson.first);
    }
    if (response.statusCode == 404) return null;
    throw Exception('Failed to load the cart for user $userId');
  }

  // Enhancement 3: add a product to a cart -> POST /carts/add
  // DummyJSON only simulates this. It replies with the product that was added,
  // and nothing is saved on the server.
  Future<Cart> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': productId, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Cart.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to add the product to the cart');
  }
}
