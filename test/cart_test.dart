import 'package:flutter_test/flutter_test.dart';
import 'package:roque_advmobprog/models/cart.dart';

void main() {
  // Shape of a real POST https://dummyjson.com/carts/add response.
  final addResponse = {
    'id': 209,
    'products': [
      {
        'id': 144,
        'title': 'Cricket Helmet',
        'price': 44.99,
        'quantity': 2,
        'total': 89.98,
        'discountPercentage': 9.64,
        'discountedPrice': 81,
        'thumbnail': 'https://example.com/t.webp',
      },
    ],
    'total': 89.98,
    'discountedTotal': 81,
    'userId': 6,
    'totalProducts': 1,
    'totalQuantity': 2,
  };

  test('reads discountedPrice from the add-to-cart response', () {
    final cart = Cart.fromJson(addResponse);
    expect(cart.userId, 6);
    expect(cart.products.single.discountedTotal, 81.0);
    expect(cart.discountedTotal, 81.0);
  });

  test('withQuantity and withProducts recalculate totals', () {
    final item = Cart.fromJson(addResponse).products.single;
    final three = item.withQuantity(3);
    expect(three.total, 134.97);
    expect(three.discountedTotal, closeTo(134.97 * (1 - 0.0964), 0.01));

    final cart = Cart.empty(6).withProducts([three, item]);
    expect(cart.totalProducts, 2);
    expect(cart.totalQuantity, 5);
    expect(cart.total, closeTo(134.97 + 89.98, 0.001));
    expect(Cart.empty(6).withProducts(const []).isEmpty, isTrue);
  });
}
