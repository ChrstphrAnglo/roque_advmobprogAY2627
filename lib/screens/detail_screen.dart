import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_text.dart';

// Enhancement 2 (earlier lab): details page shown when a product card is tapped.
// Enhancement 1 (this lab): the cart screen opens this same screen for its items.
class DetailScreen extends StatefulWidget {
  final Product product;
  const DetailScreen({super.key, required this.product});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _adding = false;

  Product get product => widget.product;

  // Enhancement 3: pass the product's values to the cart (POST /carts/add).
  Future<void> _addToCart() async {
    setState(() => _adding = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<CartProvider>().addProduct(product);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${product.title} added to your cart')));
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not add to cart. Check your connection and try again.')),
        );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: product.title,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                product.thumbnail,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.image, size: 48.sp),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: product.title,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: '${product.brand} · ${product.category}',
                    fontSize: 13.sp,
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      CustomText(
                        text: '\$${product.price.toStringAsFixed(2)}',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(width: 12.w),
                      Icon(Icons.star, color: Colors.amber, size: 18.sp),
                      SizedBox(width: 4.w),
                      CustomText(
                        text: '${product.rating} · ${product.stock} in stock',
                        fontSize: 13.sp,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  CustomText(
                    text: 'Description',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 8.h),
                  CustomText(
                    text: product.description,
                    fontSize: 14.sp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
          child: FilledButton.icon(
            onPressed: _adding ? null : _addToCart,
            icon: _adding
                ? SizedBox(
                    height: 18.h,
                    width: 18.h,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_shopping_cart),
            label: const Text('Add to cart'),
          ),
        ),
      ),
    );
  }
}
