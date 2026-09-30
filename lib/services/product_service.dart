import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/product.dart';

class ProductService {
  Future<List<Product>> getAllProducts() async {
    // DummyJSON returns 30 items by default; limit=0 returns all of them.
    final response = await http.get(Uri.parse('$host/products?limit=0'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List productsJson = data['products'] ?? [];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  // Enhancement 1: the cart only knows a product's id, so the shared detail
  // screen loads the full product with GET /products/{id}.
  Future<Product> getProductById(int id) async {
    final response = await http.get(Uri.parse('$host/products/$id'));

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load product $id');
  }
}