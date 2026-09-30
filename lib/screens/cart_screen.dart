import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'detail_screen.dart';
import '../constants.dart';
import '../models/cart.dart';
import '../providers/cart_provider.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';

// Enhancement 1: renders the cart API endpoint. Tapping an item opens the same
// detail screen the shop uses.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Enhancement 3: set up the signed-in user's own cart (starts empty).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CartProvider>().load();
    });
  }

  Future<void> _openDetail(CartProduct item) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final product = await ProductService().getProductById(item.id);
      navigator.pop();
      navigator.push(
        MaterialPageRoute(builder: (_) => DetailScreen(product: product)),
      );
    } catch (_) {
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open this product. Try again.')),
        );
    }
  }

  void _confirmOrder(CartProvider provider) {
    final total = (provider.cart?.discountedTotal ?? 0) + deliveryFee;
    provider.clear();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Order confirmed. Total \$${total.toStringAsFixed(2)}')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CartProvider>();
    final cart = provider.cart;

    if (provider.error != null && cart == null) {
      return _Message(
        icon: Icons.cloud_off,
        title: 'Could not load your cart',
        body: 'Check your connection and try again.',
        action: FilledButton(
          onPressed: () => provider.load(force: true),
          child: const Text('Try again'),
        ),
      );
    }
    if (provider.isLoading && cart == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (cart == null || cart.isEmpty) {
      return const _Message(
        icon: Icons.shopping_cart_outlined,
        title: 'Your cart is empty',
        body: 'Open a product in the shop and tap Add to cart.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            itemCount: cart.products.length,
            itemBuilder: (context, index) {
              final item = cart.products[index];
              return _CartItemCard(
                item: item,
                onTap: () => _openDetail(item),
                onQuantityChanged: (quantity) => provider.setQuantity(item.id, quantity),
              );
            },
          ),
        ),
        _Summary(cart: cart, onConfirm: () => _confirmOrder(provider)),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartProduct item;
  final VoidCallback onTap;
  final ValueChanged<int> onQuantityChanged;

  const _CartItemCard({
    required this.item,
    required this.onTap,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(10.r),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 76.r,
                  height: 76.r,
                  color: scheme.surfaceContainerHighest,
                  child: Image.network(
                    item.thumbnail,
                    fit: BoxFit.contain,
                    cacheWidth: 200,
                    errorBuilder: (_, _, _) => Icon(Icons.image, size: 24.sp),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: item.title,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text: '\$${item.price.toStringAsFixed(2)}',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                    SizedBox(height: 2.h),
                    CustomText(
                      text: '${item.discountPercentage.toStringAsFixed(0)}% off • '
                          '\$${item.discountedTotal.toStringAsFixed(2)} total',
                      fontSize: 11.sp,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              _QuantityStepper(
                quantity: item.quantity,
                onChanged: onQuantityChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  const _QuantityStepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          tooltip: 'Add one',
          onPressed: () => onChanged(quantity + 1),
          icon: const Icon(Icons.add),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: CustomText(
            key: ValueKey(quantity),
            text: '$quantity',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        // At quantity 1 the minus button becomes a remove button.
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          tooltip: quantity > 1 ? 'Remove one' : 'Remove from cart',
          onPressed: () => onChanged(quantity - 1),
          icon: Icon(quantity > 1 ? Icons.remove : Icons.delete_outline),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final Cart cart;
  final VoidCallback onConfirm;
  const _Summary({required this.cart, required this.onConfirm});

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            text: label,
            fontSize: bold ? 15.sp : 13.sp,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
          CustomText(
            text: value,
            fontSize: bold ? 16.sp : 13.sp,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: bold ? Theme.of(context).colorScheme.primary : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final discount = cart.total - cart.discountedTotal;
    final total = cart.discountedTotal + deliveryFee;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(context, 'Subtotal', '\$${cart.total.toStringAsFixed(2)}'),
          _row(context, 'Discount', '-\$${discount.toStringAsFixed(2)}'),
          _row(context, 'Delivery fee', '\$${deliveryFee.toStringAsFixed(2)}'),
          Divider(height: 16.h),
          _row(context, 'Total', '\$${total.toStringAsFixed(2)}', bold: true),
          SizedBox(height: 10.h),
          FilledButton(onPressed: onConfirm, child: const Text('Confirm order')),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56.sp, color: scheme.primary),
            SizedBox(height: 12.h),
            CustomText(text: title, fontSize: 16.sp, fontWeight: FontWeight.w600),
            SizedBox(height: 4.h),
            CustomText(
              text: body,
              fontSize: 13.sp,
              textAlign: TextAlign.center,
              color: scheme.onSurfaceVariant,
            ),
            if (action != null) ...[SizedBox(height: 16.h), action!],
          ],
        ),
      ),
    );
  }
}
