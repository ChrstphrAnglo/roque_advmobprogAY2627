import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';

/// Holds the signed-in user's cart so the shop, product details and cart screen
/// all see the same items. DummyJSON only simulates changes, so each user's
/// cart is kept on the device, under that user's id.
class CartProvider extends ChangeNotifier {
  static const _cartKeyPrefix = 'cart_';

  final CartService _service = CartService();

  Cart? _cart;
  String? _userKey;
  int? _cartUserId;
  bool _loading = false;
  Future<void>? _inflight;
  Object? _error;

  Cart? get cart => _cart;
  bool get isLoading => _loading || (_cart == null && _error == null);
  Object? get error => _error;
  int get itemCount => _cart?.totalQuantity ?? 0;

  /// Enhancement 3: builds the cart for the signed-in user from the saved user
  /// data. The id of that user picks which saved cart is read, so every account,
  /// DummyJSON or Firebase, gets its own. A new user starts with an empty cart;
  /// DummyJSON's pre-filled sample carts are not loaded.
  /// Does nothing if that user's cart is already set up, unless [force] is set.
  Future<void> load({bool force = false}) {
    // Callers that arrive while a load is running share that same load.
    return _inflight ??= _load(force).whenComplete(() => _inflight = null);
  }

  Future<void> _load(bool force) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await userService.value.getUserData();
      if (!force && _cart != null && profile.id == _userKey) return;
      _cart = null;
      _userKey = profile.id;
      _cartUserId = profile.cartUserId;
      _cart = await _read(profile.id, profile.cartUserId);
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Cart> _read(String userKey, int cartUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('$_cartKeyPrefix$userKey');
    if (saved == null) return Cart.empty(cartUserId);
    try {
      return Cart.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    } catch (_) {
      return Cart.empty(cartUserId);
    }
  }

  Future<void> _save() async {
    final cart = _cart;
    if (cart == null || _userKey == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cartKeyPrefix$_userKey', jsonEncode(cart.toJson()));
  }

  /// Enhancement 3: sends the product to POST /carts/add, then merges what the
  /// API returned into this user's cart. Throws if the request fails.
  Future<void> addProduct(Product product, {int quantity = 1}) async {
    await load();
    final current = _cart;
    if (current == null || _cartUserId == null) {
      throw _error ?? Exception('Could not load your cart.');
    }

    final added = await _service.addToCart(
      userId: _cartUserId!,
      productId: product.id,
      quantity: quantity,
    );

    final items = [...current.products];
    for (final item in added.products) {
      final index = items.indexWhere((e) => e.id == item.id);
      if (index == -1) {
        items.add(item);
      } else {
        items[index] = items[index].withQuantity(items[index].quantity + item.quantity);
      }
    }
    _cart = current.withProducts(items);
    notifyListeners();
    await _save();
  }

  void setQuantity(int productId, int quantity) {
    final current = _cart;
    if (current == null) return;
    final items = [
      for (final item in current.products)
        if (item.id != productId)
          item
        else if (quantity > 0)
          item.withQuantity(quantity),
    ];
    _cart = current.withProducts(items);
    notifyListeners();
    _save();
  }

  void clear() {
    final current = _cart;
    if (current == null) return;
    _cart = current.withProducts(const []);
    notifyListeners();
    _save();
  }
}
